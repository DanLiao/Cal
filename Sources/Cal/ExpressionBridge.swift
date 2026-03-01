// ExpressionBridge.swift
//
// Intentionally imports ONLY Expression (not Foundation) so that the
// nicklockwood/Expression class is unambiguous here — Foundation.Expression
// (macOS 15+) is not in scope. The internal typealiases below are visible
// across the entire Cal module, letting Calculator.swift use the library
// without importing Expression directly (which would cause ambiguity with
// Foundation.Expression in that file).

import Expression

// The Expression class from nicklockwood/Expression
typealias CalcExpression = Expression

// Nested types exposed without needing to write Expression.Symbol etc.
typealias CalcExpressionSymbol    = Expression.Symbol
typealias CalcExpressionEvaluator = Expression.SymbolEvaluator
typealias CalcExpressionError     = Expression.Error
typealias CalcExpressionArity     = Expression.Arity
