#include "storage/ducklake_metadata_manager.hpp"
#include "storage/ducklake_transaction.hpp"
#include "common/ducklake_util.hpp"
#include "duckdb/common/exception/conversion_exception.hpp"
#include "duckdb/common/types/blob.hpp"
#include "duckdb/planner/expression/bound_comparison_expression.hpp"
#include "duckdb/planner/expression/bound_conjunction_expression.hpp"
#include "duckdb/planner/expression/bound_constant_expression.hpp"
#include "duckdb/planner/expression/bound_function_expression.hpp"
#include "duckdb/planner/expression/bound_operator_expression.hpp"
#include "duckdb/planner/expression/bound_reference_expression.hpp"

namespace duckdb {

string DuckLakeMetadataManager::GenerateInlinedFilter(const Expression &expression, const string &column,
                                                      const LogicalType &type,
                                                      optional_ptr<const DuckLakeColumnStats> stats) {
	if (type.HasAlias() || (type.id() == LogicalTypeId::VARCHAR && !StringType::GetCollation(type).empty())) {
		return string();
	}
	if (auto child = ExpressionFilter::GetOptionalFilterChild(expression)) {
		return GenerateInlinedFilter(*child, column, type, stats);
	}
	auto is_column = [&](const Expression &expr) {
		return expr.GetExpressionClass() == ExpressionClass::BOUND_REF &&
		       expr.Cast<BoundReferenceExpression>().Index() == 0 && expr.GetReturnType() == type;
	};
	auto is_constant = [&](const Expression &expr) {
		return expr.GetExpressionClass() == ExpressionClass::BOUND_CONSTANT && expr.GetReturnType() == type;
	};
	if (BoundComparisonExpression::IsComparison(expression)) {
		auto &comparison = expression.Cast<BoundFunctionExpression>();
		auto &left = BoundComparisonExpression::Left(comparison);
		auto &right = BoundComparisonExpression::Right(comparison);
		if (!((is_column(left) && is_constant(right)) || (is_constant(left) && is_column(right)))) {
			return string();
		}
	} else if (expression.GetExpressionClass() == ExpressionClass::BOUND_OPERATOR) {
		auto &op = expression.Cast<BoundOperatorExpression>();
		if (op.GetChildren().empty() || !is_column(*op.GetChildren()[0])) {
			return string();
		}
		switch (expression.GetExpressionType()) {
		case ExpressionType::COMPARE_IN:
			if (op.GetChildren().size() < 2) {
				return string();
			}
			for (idx_t i = 1; i < op.GetChildren().size(); i++) {
				if (!is_constant(*op.GetChildren()[i])) {
					return string();
				}
			}
			break;
		case ExpressionType::OPERATOR_IS_NULL:
		case ExpressionType::OPERATOR_IS_NOT_NULL:
			if (op.GetChildren().size() != 1) {
				return string();
			}
			break;
		default:
			return string();
		}
	} else if (expression.GetExpressionClass() == ExpressionClass::BOUND_CONJUNCTION) {
		auto &conjunction = expression.Cast<BoundConjunctionExpression>();
		vector<string> children;
		for (auto &child : conjunction.GetChildren()) {
			auto filter = GenerateInlinedFilter(*child, column, type, stats);
			if (filter.empty()) {
				if (expression.GetExpressionType() == ExpressionType::CONJUNCTION_OR) {
					return string();
				}
				continue;
			}
			if (child->GetExpressionClass() == ExpressionClass::BOUND_CONJUNCTION &&
			    child->GetExpressionType() == expression.GetExpressionType()) {
				children.push_back(std::move(filter));
			} else {
				children.push_back("(" + filter + ")");
			}
		}
		return StringUtil::Join(children,
		                        expression.GetExpressionType() == ExpressionType::CONJUNCTION_OR ? " OR " : " AND ");
	} else {
		return string();
	}
	try {
		return InlinedFilterToSQL(expression, column, type, stats);
	} catch (ConversionException &) {
		return string();
	}
}

string DuckLakeMetadataManager::FormatInlinedFilter(const Expression &expression, const string &column,
                                                    const std::function<string(const Value &)> &constant_to_sql) {
	if (BoundComparisonExpression::IsComparison(expression)) {
		ExpressionType comparison_type;
		auto constant = ExpressionFilter::TryGetColumnConstantComparison(expression.Cast<BoundFunctionExpression>(),
		                                                                 comparison_type);
		D_ASSERT(constant);
		auto value = constant_to_sql(constant->GetValue());
		if (value.empty()) {
			return string();
		}
		return "(" + column + " " + ExpressionTypeToOperator(comparison_type) + " " + value + ")";
	}
	auto &op = expression.Cast<BoundOperatorExpression>();
	if (expression.GetExpressionType() == ExpressionType::COMPARE_IN) {
		vector<string> values;
		for (idx_t i = 1; i < op.GetChildren().size(); i++) {
			auto value = constant_to_sql(op.GetChildren()[i]->Cast<BoundConstantExpression>().GetValue());
			if (value.empty()) {
				return string();
			}
			values.push_back(std::move(value));
		}
		return column + " IN (" + StringUtil::Join(values, ", ") + ")";
	}
	return column + (expression.GetExpressionType() == ExpressionType::OPERATOR_IS_NULL ? " IS NULL" : " IS NOT NULL");
}

string DuckLakeMetadataManager::InlinedFilterToSQL(const Expression &expression, const string &column,
                                                   const LogicalType &type, optional_ptr<const DuckLakeColumnStats>) {
	switch (type.id()) {
	case LogicalTypeId::BOOLEAN:
	case LogicalTypeId::TINYINT:
	case LogicalTypeId::SMALLINT:
	case LogicalTypeId::INTEGER:
	case LogicalTypeId::BIGINT:
	case LogicalTypeId::UTINYINT:
	case LogicalTypeId::USMALLINT:
	case LogicalTypeId::UINTEGER:
	case LogicalTypeId::UBIGINT:
	case LogicalTypeId::HUGEINT:
	case LogicalTypeId::UHUGEINT:
	case LogicalTypeId::DECIMAL:
	case LogicalTypeId::FLOAT:
	case LogicalTypeId::DOUBLE:
	case LogicalTypeId::VARCHAR:
	case LogicalTypeId::BLOB:
	case LogicalTypeId::DATE:
	case LogicalTypeId::TIMESTAMP:
	case LogicalTypeId::TIMESTAMP_SEC:
	case LogicalTypeId::TIMESTAMP_MS:
	case LogicalTypeId::TIMESTAMP_NS:
	case LogicalTypeId::TIMESTAMP_TZ:
	case LogicalTypeId::TIMESTAMP_TZ_NS:
		break;
	default:
		return string();
	}
	return FormatInlinedFilter(expression, CastColumnToTarget(column, type), [&](const Value &value) {
		if (!value.IsNull() && (type.id() == LogicalTypeId::VARCHAR || type.id() == LogicalTypeId::BLOB)) {
			// Keep binary contents and metadata placeholders out of the generated SQL text.
			auto literal = "from_base64('" + Blob::ToBase64(StringValue::Get(value)) + "')";
			return type.id() == LogicalTypeId::VARCHAR ? "decode(" + literal + ")" : literal;
		}
		auto literal = DuckLakeUtil::ValueToSQL(*this, *transaction.GetConnection().context, value);
		if (type.IsIntegral()) {
			return literal;
		}
		// The literal must have the column's type, notably for single-precision comparisons.
		return "CAST(" + literal + " AS " + type.ToString() + ")";
	});
}

} // namespace duckdb
