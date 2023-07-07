```
<expr> := TRUE|FALSE|<num>|<op>|<fun>|<cond>
<fun>  := : <fun-name> <expr> ;
<cond> := <expr> IF <expr> ((THEN|ENDIF) | ELSE <expr> (THEN|ENDIF))
```

The accepted language is the super set of above

```: fn IF ;``` is accepted, it will lead to an error while evaluating ```fn```  
```IF ELSE ELSE``` is accepted too

Totally interactive

efficacity

pretty print

trace failure?

TODO
dico -> arbre lexical