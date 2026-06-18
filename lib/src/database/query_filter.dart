enum FilterOperator { equal, greaterThan, lessThan }

class QueryFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  QueryFilter.eq(this.field, this.value) : operator = FilterOperator.equal;
  QueryFilter.gt(this.field, this.value) : operator = FilterOperator.greaterThan;
  QueryFilter.lt(this.field, this.value) : operator = FilterOperator.lessThan;
}
