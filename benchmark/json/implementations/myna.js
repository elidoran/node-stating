'use strict';
var M, G, json, convert

M = require('myna-parser')

G = {}

// These are helper rules, they do not create nodes in the parse tree.
// G.escapedChar    = M.seq('\\', M.char('\\/bfnrt"'));
// G.escapedUnicode = M.seq('\\u', M.hexDigit.repeat(4));
// G.quoteChar      = M.choice(G.escapedChar, G.escapedUnicode, M.charExcept('"'));
G.quoteChar      = M.charExcept('"');
G.fraction       = M.seq('.', M.digit.zeroOrMore);
G.plusOrMinus    = M.char('+-');
G.exponent       = M.seq(M.char('eE'), G.plusOrMinus.opt, M.digits);
G.comma          = M.text(',').ws;

// defer execution until after the other rules are defined
// to allow recursion.
// both G.array and G.pair require G.value.
// and G.value requires both G.array and G.object (which uses G.pair).
G.value = M.delay(function() {
  return M.choice(G.string, G.number, G.object, G.array, G.bool, G.null);
}).ast;

// The following rules create nodes in the abstract syntax tree
G.string         = M.doubleQuoted(G.quoteChar.zeroOrMore).ast;
G.null           = M.keyword('null').ast;
G.bool           = M.keywords('true', 'false').ast;
// G.number         = M.seq(G.plusOrMinus.opt, M.integer, G.fraction.opt, G.exponent.opt).ast;
G.number         = M.char('0123456789-.eE+').oneOrMore.ast;
G.array          = M.bracketed(M.delimited(G.value.ws, G.comma)).ast;
G.pair           = M.seq(G.string, M.ws, ':', M.ws, G.value.ws).ast;
G.object         = M.braced(M.delimited(G.pair.ws, G.comma)).ast;

M.registerGrammar('json', G);

// run in a closure so we can make local variables for all the rule ID's.
convert = (function() {
  // var valueId  = G.value.id
  var objectId = G.object.id
    , arrayId  = G.array.id
    , stringId = G.string.id
    , numberId = G.number.id
    , boolId   = G.bool.id
    , nullId   = G.null.id
    // get the char code of a t for the bool match
    , T        = 't'.charCodeAt(0)
    // same as the T above, except only for a workaround
    , V        = 'v'.charCodeAt(0)

  return function convert(ast) {

    var array, pair, key, result, i, end, node;

    if (ast == null) return;

    switch (ast.rule.id) {

      // the ID changes every time because the Myna.Delay re-resolves it every time it's used.
      // when resolved, it creates a brand new Myna.Choice (i'm using myna.choice() in the delay).
      // case valueId:  return convert(ast.children[0])

      case objectId:
        result = {};
        array = ast.children
        for (i = 0, end = array.length; i < end; i++) {
          pair = array[i];
          node = pair.children[0]
          key = node.input.slice(node.start + 1, node.end - 1)
          result[key] = convert(pair.children[1]);
        }
        return result;

      case arrayId:
        result = [];
        array = ast.children;
        for (i = 0, end = array.length; i < end; i++) {
          result[result.length] = convert(array[i]);
        }
        return result;

      case stringId: return ast.input.slice(ast.start + 1, ast.end - 1);
      case numberId: return Number(ast.allText);
      case nullId  : return null;
      case boolId  : return ast.input.charCodeAt(ast.start) === T

      default:
        // the delay wrapper re-resolves every time
        // creating a new id for every `value` node.
        // so, check for it's name.
        // if (ast.rule.name === 'value') {
        // instead, let's just check the name's first letter
        if (ast.rule.name.charCodeAt(0) === V) {
          return convert(ast.children[0])
        }
    }

  };
})()

json = G.value

module.exports = function parseJson(input) {
  var ast, result
  ast = M.parse(json, input)
  result = convert(ast)
  return result
}
