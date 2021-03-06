{-# LANGUAGE FlexibleContexts #-}
import Parser hiding (type')
import Test.Hspec

main :: IO ()
main = hspec spec

getRight :: Either a b -> Maybe b
getRight y = do 
    Right x <- return y
    return x

parseIExp input = parse' iExpParser input
parseExp input = parse' expParser input
parseTld input = parse' tldParser input


spec = do
    describe "integer expressions" $ do
        it "PASSES on good parser input" $ do
            parseIExp "1+1" `shouldBe` (Right $ IExp (IExpInt 1) Plus (IExpInt 1))
            parseIExp "x-1" `shouldBe` (Right $ IExp (IExpVar $ Identifier "x") Minus (IExpInt 1))
            parseIExp "x*y" `shouldBe` (Right $ IExp (IExpVar $ Identifier "x") Mult (IExpVar $ Identifier "y"))
            parseIExp "x/1" `shouldBe` (Right $ IExp (IExpVar $ Identifier "x") Div (IExpInt 1))
            parseIExp "x" `shouldBe` (Right $ IExpVar $ Identifier "x")
            parseIExp "1" `shouldBe` (Right $ IExpInt 1)
            parseIExp "2==y" `shouldBe` (Right $ IExp (IExpInt 2) Equals (IExpVar $ Identifier "y"))
            parseIExp "2^y" `shouldBe` (Right $ IExp (IExpInt 2) Exponent (IExpVar $ Identifier "y"))
            parseIExp "2^y*3-4" `shouldBe` (Right (IExp (IExpInt 2) Exponent (IExp (IExpVar $ Identifier "y") Mult (IExp (IExpInt 3) Minus (IExpInt 4)))))
            parseIExp "2*x+y" `shouldBe` (Right (IExp (IExpInt 2) Mult (IExp (IExpVar $ Identifier "x") Plus (IExpVar $ Identifier "y"))))
            parseIExp "x*y==z" `shouldBe` (Right (IExp (IExpVar $ Identifier "x") Mult (IExp (IExpVar $ Identifier "y") Equals (IExpVar $ Identifier "z"))))

        it "FAILS on bad parser input" $ do
            (getRight $ parseIExp "2*_") `shouldBe` Nothing
            (getRight $ parseIExp "2*8a") `shouldBe` Nothing
            (getRight $ parseIExp "3^+2") `shouldBe` Nothing
            (getRight $ parseIExp "3^") `shouldBe` Nothing
            (getRight $ parseIExp "x23232 + _2") `shouldBe` Nothing
            (getRight $ parseIExp "_2+(2)") `shouldBe` Nothing
            (getRight $ parseIExp "") `shouldBe` Nothing
            (getRight $ parseIExp "\\(x):String{x}:String") `shouldBe` Nothing


    describe "expressions" $ do
        it "PASSES on good parser input" $ do
            parseExp "x" `shouldBe` (Right $ ExpVariable $ Identifier "x")
            parseExp "x23232" `shouldBe` (Right $ ExpVariable $ Identifier "x23232")
            parseExp "12323232" `shouldBe` (Right $ ExpInteger 12323232)
            parseExp "\"xyz\"" `shouldBe` (Right $ ExpString "xyz")
            parseExp "\\(x):String{x}:String" `shouldBe` (Right (ExpLambda (ExpVariable $ Identifier "x") (Type $ Identifier "String") (ExpVariable $ Identifier "x") (Type $ Identifier "String")))
            parseExp "x*y" `shouldBe` (Right $ ExpIExp $ IExp (IExpVar $ Identifier "x") Mult (IExpVar $ Identifier "y"))
            parseExp "name(x)" `shouldBe` (Right (ExpUnaryFOCall (Identifier "name") (ExpVariable $ Identifier "x")))
            parseExp "name()" `shouldBe` (Right (ExpNullaryFOCall (Identifier "name")))
            parseExp "case(x):Integer{name()->\"xyz\"}" `shouldBe` (Right (ExpPatternMatchCall (Identifier "x") (Type $ Identifier "Integer") [PatternMatchExpression (Identifier "name") [] (ExpString "xyz")] ))
            parseExp "case(x):Integer{name()->\"xyz\"other()->\"abc\"}" `shouldBe` (Right (ExpPatternMatchCall (Identifier "x") (Type $ Identifier "Integer") [PatternMatchExpression (Identifier "name") [] (ExpString "xyz"), PatternMatchExpression (Identifier "other") [] (ExpString "abc")] ))
            parseExp "case(x):Integer{name(thing)->\"xyz\"}" `shouldBe` (Right (ExpPatternMatchCall (Identifier "x") (Type $ Identifier "Integer") [PatternMatchExpression (Identifier "name") [Identifier "thing"] (ExpString "xyz")] ))
            parseExp "case(x):Integer{name(thing,other)->\"xyz\"}" `shouldBe` (Right (ExpPatternMatchCall (Identifier "x") (Type $ Identifier "Integer") [PatternMatchExpression (Identifier "name") [Identifier "thing", Identifier "other"] (ExpString "xyz")] ))
            parseExp "<1,2,3,4>:<Integer,Integer,Integer,Integer>" `shouldBe` (Right (ExpTuple [ExpInteger 1, ExpInteger 2, ExpInteger 3, ExpInteger 4] $ ProductType $ take 4 $ repeat $ mkType "Integer"))
            parseExp "a->add:addOne" `shouldBe` (Right (TypeclassCallVar (ExpAtomVar (Identifier "a")) (Typeclass (Identifier "add")) (TypeclassFunc (Identifier "addOne"))))
            parseExp "5->add:addOne" `shouldBe` (Right (TypeclassCallInt (ExpAtomInt 5) (Typeclass (Identifier "add")) (TypeclassFunc (Identifier "addOne"))))
            parseExp "\"hi\"->add:addOne" `shouldBe` (Right (TypeclassCallStr (ExpAtomStr "hi") (Typeclass (Identifier "add")) (TypeclassFunc (Identifier "addOne"))))


        it "FAILS on bad parser input" $ do
            (getRight $ parseExp "2a") `shouldBe` Nothing
            (getRight $ parseExp "x23232 + _2") `shouldBe` Nothing
            (getRight $ parseExp "\"xyz\" + 5") `shouldBe` Nothing
            (getRight $ parseExp "") `shouldBe` Nothing
            (getRight $ parseExp "\\(x):String{x}:") `shouldBe` Nothing
            (getRight $ parseExp "name(x") `shouldBe` Nothing
            (getRight $ parseExp "name( )") `shouldBe` Nothing
            (getRight $ parseExp "\"xyz") `shouldBe` Nothing
            (getRight $ parseExp "a->add::addOne") `shouldBe` Nothing



    describe "top level function and data definitions" $ do
        it "PASSES on good parser input" $ do
            parseTld "datanewType=Nullary()" `shouldBe` (Right (DataDef (Identifier "newType") [NullaryConstructor $ Identifier "Nullary"]))
            parseTld "datanewType=Calculate(Integer)" `shouldBe` (Right (DataDef (Identifier "newType") [UnaryConstructor (Identifier "Calculate") (Type $ Identifier "Integer")]))
            parseTld "datanewType=SomeFunct()|Calculate(Integer)" `shouldBe` (Right (DataDef (Identifier "newType") [(NullaryConstructor (Identifier "SomeFunct")), (UnaryConstructor (Identifier "Calculate") (Type $ Identifier "Integer"))]))
            parseTld "func=funk(a:string):string{a}" `shouldBe` (Right (Func (FuncDefUnary (Identifier "funk") (Identifier "a") (Type $ Identifier "string") (ExpVariable $ Identifier "a") (Type $ Identifier "string"))))
            parseTld "func=funk():string{a}" `shouldBe` (Right (Func (FuncDefNullary (Identifier "funk") (ExpVariable $ Identifier "a") (Type $ Identifier "string"))))
            parseTld "func=funk():string{x*y}" `shouldBe` (Right (Func (FuncDefNullary (Identifier "funk") (ExpIExp (IExp (IExpVar (Identifier "x")) Mult (IExpVar (Identifier "y")))) (Type (Identifier "string")))))
            parseTld "func=funk():string{x*y+x==5}" `shouldBe` (Right (Func (FuncDefNullary (Identifier "funk") (ExpIExp (IExp (IExpVar (Identifier "x")) Mult (IExp (IExpVar (Identifier "y")) Plus (IExp (IExpVar (Identifier "x")) Equals (IExpInt 5))))) (Type (Identifier "string")))))
            parseTld "typeclass:equals:eq[A->B]" `shouldBe` (Right (TypeclassDef (Identifier "equals") [SigDef (Identifier "eq") (Generic (GIdentifier "A")) (Generic (GIdentifier "B"))]))
            parseTld "instance:equals:eq[String->String](a){a}" `shouldBe` (Right (TypeclassImp (Identifier "equals") [SigImp (Identifier "eq") (Type (Identifier "String")) (Type (Identifier "String")) (Identifier "a") (ExpVariable (Identifier "a"))]))
            parseTld "typeclass:equals:eq[A->B]neq[C->D]" `shouldBe` (Right (TypeclassDef (Identifier "equals") [SigDef (Identifier "eq") (Generic (GIdentifier "A")) (Generic (GIdentifier "B")),SigDef (Identifier "neq") (Generic (GIdentifier "C")) (Generic (GIdentifier "D"))]))
            parseTld "instance:equals:eq[String->String](a){a}eq[Int->Int](b){b+1}" `shouldBe` (Right (TypeclassImp (Identifier "equals") [SigImp (Identifier "eq") (Type (Identifier "String")) (Type (Identifier "String")) (Identifier "a") (ExpVariable (Identifier "a")),SigImp (Identifier "eq") (Type (Identifier "Int")) (Type (Identifier "Int")) (Identifier "b") (ExpIExp (IExp (IExpVar (Identifier "b")) Plus (IExpInt 1)))]))
            parseTld "instance:equals:eq[String->String](a){a}neq[String->Int](c){1}" `shouldBe` (Right (TypeclassImp (Identifier "equals") [SigImp (Identifier "eq") (Type (Identifier "String")) (Type (Identifier "String")) (Identifier "a") (ExpVariable (Identifier "a")),SigImp (Identifier "neq") (Type (Identifier "String")) (Type (Identifier "Int")) (Identifier "c") (ExpInteger 1)]))

        it "FAILS on bad parser input" $ do
            (getRight $ parseTld "datanewType=Nullary(") `shouldBe` Nothing
            (getRight $ parseTld "datanewType=Calculate") `shouldBe` Nothing
            (getRight $ parseTld "func=funk():string{}") `shouldBe` Nothing
            (getRight $ parseTld "func=funkk():{}") `shouldBe` Nothing
            (getRight $ parseTld "func=funck():string{x*_}") `shouldBe` Nothing
            (getRight $ parseTld "typeclass:equals:eq[a-> ]") `shouldBe` Nothing
            (getRight $ parseTld "typeclass:equals:eq[a b]") `shouldBe` Nothing
