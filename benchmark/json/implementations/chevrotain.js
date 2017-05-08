var chevrotain = require("chevrotain");

// ----------------- lexer -----------------
var createToken = chevrotain.createToken;
var Lexer = chevrotain.Lexer;
var Parser = chevrotain.Parser;

// In ES6, custom inheritance implementation (such as 'extendToken(...)') can be replaced with simple "class X extends Y"...
var True = createToken({name: "True", pattern: /true/});
var False = createToken({name: "False", pattern: /false/});
var Null = createToken({name: "Null", pattern: /null/});
var LCurly = createToken({name: "LCurly", pattern: /{/});
var RCurly = createToken({name: "RCurly", pattern: /}/});
var LSquare = createToken({name: "LSquare", pattern: /\[/});
var RSquare = createToken({name: "RSquare", pattern: /]/});
var Comma = createToken({name: "Comma", pattern: /,/});
var Colon = createToken({name: "Colon", pattern: /:/});
var StringLiteral = createToken({name: "StringLiteral", pattern: /"(?:[^\\"]|\\(?:[bfnrtv"\\/]|u[0-9a-fA-F]{4}))*"/});
var NumberLiteral = createToken({name: "NumberLiteral", pattern: /-?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?/});
var WhiteSpace = createToken({name: "WhiteSpace", pattern: /\s+/, group: Lexer.SKIPPED});

var allTokens = [WhiteSpace, NumberLiteral, StringLiteral, LCurly, RCurly, LSquare, RSquare, Comma, Colon, True, False, Null];
var JsonLexer = new Lexer(allTokens);


// ----------------- parser -----------------

function JsonParserES5(input) {
    // invoke super constructor
    Parser.call(this, input, allTokens, {
            // by default the error recovery / fault tolerance capabilities are disabled
            // use this flag to enable them
            recoveryEnabled: false
        }
    );

    // not mandatory, using <$> (or any other sign) to reduce verbosity (this. this. this. this. .......)
    var $ = this;

    this.RULE("object", function() {
        var object, key

        $.CONSUME(LCurly);

        object = {}

        $.MANY_SEP({
          SEP: Comma, DEF: function () {
            key = $.SUBRULE($.string)
            $.CONSUME(Colon)
            object[key] = $.SUBRULE($.value)
          }
        });

        $.CONSUME(RCurly);

        return object
    });

    this.RULE("array", function() {
        var array

        $.CONSUME(LSquare);

        array = []

        $.MANY_SEP({
          SEP: Comma, DEF: function () {
            array[array.length] = $.SUBRULE($.value);
          }
        });

        $.CONSUME(RSquare);

        return array
    });

    this.RULE("number", function(){
      var result = $.CONSUME(NumberLiteral)
      return Number(result.image)
    })

    this.RULE("string", function(){
      var result = $.CONSUME(StringLiteral)
      return result.image.slice(1, -1)
    })


    this.RULE("value", function() {
        return $.OR([
            {ALT: function() { return $.SUBRULE($.object) }},
            {ALT: function() { return $.SUBRULE($.array) }},
            {ALT: function() { return $.SUBRULE($.string) }},
            {ALT: function() { return $.SUBRULE($.number) }},
            {ALT: function() { $.CONSUME(True) ; return true }},
            {ALT: function() { $.CONSUME(False) ; return false }},
            {ALT: function() { $.CONSUME(Null) ; return null }}
        ]);
    });

    // very important to call this after all the rules have been defined.
    // otherwise the parser may not work correctly as it will lack information
    // derived during the self analysis phase.
    Parser.performSelfAnalysis(this);
}

// inheritance as implemented in javascript in the previous decade... :(
JsonParserES5.prototype = Object.create(Parser.prototype);
JsonParserES5.prototype.constructor = JsonParserES5;

// ----------------- wrapping it all together -----------------

// reuse the same parser instance.
var parser = new JsonParserES5([]);

module.exports = function(text) {
    var lexResult = JsonLexer.tokenize(text);

    // setting a new input will RESET the parser instance's state.
    parser.input = lexResult.tokens;

    // any top level rule may be used as an entry point
    var value = parser.value();

    return value
    // return {
    //     value:       value, // this is a pure grammar, the value will always be <undefined>
    //     lexErrors:   lexResult.errors,
    //     parseErrors: parser.errors
    // };
};
