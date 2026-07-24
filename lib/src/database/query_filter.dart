enum FilterOperator {
  equal,
  notEqual,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  inFilter,
}

class QueryFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  QueryFilter.eq(this.field, this.value) : operator = FilterOperator.equal;
  QueryFilter.neq(this.field, this.value) : operator = FilterOperator.notEqual;
  QueryFilter.gt(this.field, this.value)
    : operator = FilterOperator.greaterThan;
  QueryFilter.gte(this.field, this.value)
    : operator = FilterOperator.greaterThanOrEqual;
  QueryFilter.lt(this.field, this.value) : operator = FilterOperator.lessThan;
  QueryFilter.lte(this.field, this.value)
    : operator = FilterOperator.lessThanOrEqual;
  QueryFilter.inFilter(this.field, List<dynamic> values)
    : operator = FilterOperator.inFilter,
      value = values;
}
