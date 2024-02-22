import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_cloud_firestore/src/fire/constants.dart';
import 'package:flutter/foundation.dart';

extension QueryExt on Query<Object?> {
  Query<Object?> itemsPerPage(int items) {
    return limit(items);
  }

  Query<Object?> maxActivePages(int maxPages) {
    return where(
      maxActivePagesKey,
      isEqualTo: maxPages,
    );
  }

  Query<Object?> removeLibFields(
    Query<Object?> base,
  ) {
    return _parseQuery(
      base,
      (String field, String operator, dynamic value) {
        return !ignoreKeys.contains(field);
      },
    );
  }

  T? getValueOf<T>(
    Query<Object?> base,
    String field,
    String operator,
  ) {
    T? value;
    _parseQuery(
      base,
      (String fieldCheck, String operatorCheck, dynamic valueCheck) {
        if (field == fieldCheck &&
            operator == operatorCheck &&
            valueCheck != null) {
          try {
            value = valueCheck as T;
          } catch (e) {
            if (kDebugMode) {
              print('🔥 $e');
            }
          }
        }
        return true;
      },
    );
    return value;
  }

  Query _parseQuery(
    Query<Object?> base,
    bool Function(String, String, dynamic) include,
  ) {
    Query<Object?>? recreatedQuery;

    for (var entries in parameters.entries) {
      if (entries.key == 'where') {
        if (entries.value is List) {
          for (var whereParam in entries.value) {
            if (whereParam is List) {
              if (whereParam.first is FieldPath) {
                final String field =
                    (whereParam.first as FieldPath).components.join('.');
                final String operator = whereParam[1];
                final dynamic value = whereParam[2];

                if (!include(field, operator, value)) {
                  continue;
                }

                if (operator == '==') {
                  if (value == null) {
                    recreatedQuery =
                        (recreatedQuery ?? base).where(field, isNull: true);
                  } else {
                    recreatedQuery =
                        (recreatedQuery ?? base).where(field, isEqualTo: value);
                  }
                } else if (operator == '!=') {
                  if (value == null) {
                    recreatedQuery =
                        (recreatedQuery ?? base).where(field, isNull: false);
                  } else {
                    recreatedQuery = (recreatedQuery ?? base)
                        .where(field, isNotEqualTo: value);
                  }
                } else if (operator == '<') {
                  recreatedQuery =
                      (recreatedQuery ?? base).where(field, isLessThan: value);
                } else if (operator == '<=') {
                  recreatedQuery = (recreatedQuery ?? base)
                      .where(field, isLessThanOrEqualTo: value);
                } else if (operator == '>') {
                  recreatedQuery = (recreatedQuery ?? base)
                      .where(field, isGreaterThan: value);
                } else if (operator == '>=') {
                  recreatedQuery = (recreatedQuery ?? base)
                      .where(field, isGreaterThanOrEqualTo: value);
                } else if (operator == 'array-contains') {
                  recreatedQuery = (recreatedQuery ?? base)
                      .where(field, arrayContains: value);
                } else if (operator == 'array-contains-any') {
                  recreatedQuery = (recreatedQuery ?? base)
                      .where(field, arrayContainsAny: value);
                } else if (operator == 'in') {
                  recreatedQuery =
                      (recreatedQuery ?? base).where(field, whereIn: value);
                } else if (operator == 'not-in') {
                  recreatedQuery =
                      (recreatedQuery ?? base).where(field, whereNotIn: value);
                }
              }
            }
          }
        }
      } else if (entries.key == 'orderBy') {
        if (entries.value is List) {
          final List<List<dynamic>> orderByParams = entries.value;
          for (var param in orderByParams) {
            if (param.isNotEmpty) {
              if (param.first is FieldPath) {
                final String field =
                    (param.first as FieldPath).components.join('.');
                final bool descending = param.length > 1 ? param[1] : false;
                recreatedQuery = (recreatedQuery ?? base)
                    .orderBy(field, descending: descending);
              }
            }
          }
        }
      } else if (entries.key == 'startAt') {
        if (entries.value == null) continue;
        if (entries.value is DocumentSnapshot) {
          recreatedQuery =
              (recreatedQuery ?? base).startAtDocument(entries.value);
        } else {
          recreatedQuery = (recreatedQuery ?? base).startAt(entries.value);
        }
      } else if (entries.key == 'startAfter') {
        if (entries.value == null) continue;
        if (entries.value is DocumentSnapshot) {
          recreatedQuery =
              (recreatedQuery ?? base).startAfterDocument(entries.value);
        } else {
          recreatedQuery = (recreatedQuery ?? base).startAfter(entries.value);
        }
      } else if (entries.key == 'endAt') {
        if (entries.value == null) continue;
        if (entries.value is DocumentSnapshot) {
          recreatedQuery =
              (recreatedQuery ?? base).endAtDocument(entries.value);
        } else {
          recreatedQuery = (recreatedQuery ?? base).endAt(entries.value);
        }
      } else if (entries.key == 'endBefore') {
        if (entries.value == null) continue;
        if (entries.value is DocumentSnapshot) {
          recreatedQuery =
              (recreatedQuery ?? base).endBeforeDocument(entries.value);
        } else {
          recreatedQuery = (recreatedQuery ?? base).endBefore(entries.value);
        }
      } else if (entries.key == 'limit') {
        if (entries.value == null) continue;
        recreatedQuery = (recreatedQuery ?? base).limit(entries.value);
      } else if (entries.key == 'limitToLast') {
        if (entries.value == null) continue;
        recreatedQuery = (recreatedQuery ?? base).limitToLast(entries.value);
      }
    }

    return recreatedQuery ?? this;
  }
}
