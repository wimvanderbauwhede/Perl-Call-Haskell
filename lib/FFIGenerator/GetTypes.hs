module FFIGenerator.GetTypes ( getFFITypes, hasSimpleSig, getTypes )
where    
import Data.Typeable

getTypes f = 
 let
    typestr = show $ typeOf f
 in    
    filter (/= "->") (words typestr)

convertToCType t 
    | t == "Int" = "CLong"
    | t == "Double" = "CDouble"
    | t == "[Char]" = "CString"
    | t == "String" = "CString"
    | otherwise = "serialise" -- error $ "Type "++t++" not supported"

hasSimpleSig f = 
    let
        tts =map convertToCType (getTypes f)
    in
        foldl (&&) True (map (/= "serialise") tts)
             
getFFITypes f 
  | hasSimpleSig f = 
    let
        tts =map convertToCType (getTypes f)
        res = last tts
    in
        (init tts)++["IO "++res]
  | otherwise = ["CString","IO CString"]

