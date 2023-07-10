# Pf23REPL

> Tianxiang XIA

## Pf23

Pf23 est un langage conçu par Monsieur Emmanuel Chailloux à une data inconnue pour l'UE LU2IN119 été-2023 qui ressemble à PostScript.

## Syntaxe

(c.f. LU2IN119.pdf)

```
<expr> ::= <num>|<bool>|<op>|<dec>|<cond>|<id>|<expr> <expr>
<dec>  ::= : <id> <expr> ;
<cond> ::= <expr> IF <expr> ((THEN|ENDIF) | ELSE <expr> (THEN|ENDIF))
<op>   ::= +|-|*|/|<|>|=|<>|DUP|DROP|SWAP|ROT
<num>  ::=	[-] (0…9) { 0…9 ∣ _ }
          ∣ [-] (0x ∣ 0X) (0…9 ∣ A…F ∣ a…f) { 0…9 ∣ A…F ∣ a…f ∣ _ }
          ∣ [-] (0o ∣ 0O) (0…7) { 0…7 ∣ _ }
          ∣ [-] (0b ∣ 0B) (0…1) { 0…1 ∣ _ }
<bool> ::= TRUE|FALSE
<id>   ::= une suite non vide de char qui n'est pas un mot-clé défini dessus
```

## Sémantique

(c.f. LU2IN119.pdf)

Un ```<expr>``` peut s'appliquer à une pile et soit produire une erreur, soit retourner
une pile de résultat.

L'ensemble des expressions sans erreur d'exécution en s'appliquant à une pile vide est le langage de Pf23.

Le suivant est les effets de quelques expressions sur des piles; l'effet d'une expression quelconque est la composition des effets décrits dessous.

```
Description de l'effet d'une opérateur : op (pile -- nouvelle pile)

opérateurs de pile
- DUP  (n -- n n)         (dupliquer le sommet de pile)
- DROP ( n -- )           (supprimer le sommet de pile)
- SWAP ( a b -- b a)      (échanger des deux éléments du sommet)
- ROT  ( a b c -- b c a)  (rotation des trois éléments du sommet)

opérateurs arithmétiques et de comparaison
- *, /,+,- (a b -- b op a ) b op a dénote un entier.
- =,<>,<,> (a b -- b op a ) b op a dénote un booléen (TRUE ou FALSE).

- <num> ( -- <num> )
- <bool> ( -- <bool> )

<dec> définit une fonction qui pourra être appelée par <id>  
<cond> s'exécute de manière dépendante de la tête booléenne de la pile (IF supprime la tête)
```

Les imbrications des fonctions et des conditionnels sont possible. ```IF ... THEN``` crée une portée de variables à l'intérieur ainsi comme ```: fn ... ;``` . L'accès des vairables se fait lors de l'exécution de fonction au lieu de définition de fonction.

## Exécution, REPL

À chaque saisie, on passe au programme une expression qui sera appliquée à la pile courant.

```
pf23> 1 2                          
2 1
pf23> *
2
pf23> : CARRE DUP * ;
2
pf23> CARRE
4
```

Le language accepté par le programme est un sur-ensemble non large du langage Pf23 par choix d'implémentation. L'exécution reste pourtant raisonnable. Par exemple:

```: fn IF ;``` est acceptée, on aura une erreur quand on applique ```fn```  
```IF A ELSE B ELSE C``` est accepté aussi, et on exécute A, C si ```IF``` rencontre une valeur vraie à la tété de la pile.

```
pf23> 1 1 = IF 1 ELSE 2 ELSE 3 THEN
3 1
```

## Implémentation, algorithme

Dans cette section on parle de ce que fait le code ```lib/pf23.ml```. On utilise des termes plus proches du code (e.g. stack -> pile).

On a un stack et on reçoit un élément, ce que se passe pour le stack est
la seule chose le programme retourne à l'utilisateur.

Soit cet élément modifie le stack soit non. Si cet élément modifie le stack,
soit il est un opérateur basique ```<op>```, on peut l'appliquer directement au stack, soit il est un appel de fonction, on a besoin de savoir sa définition.

Donc le programme a besoin de savoir au moins 1. le stack actuel; 2. si l'on est en état effectif ou non (dans un milieu d'une définition de fonction ou une branche de if non effective); 3. des dictionnaires pour des portées. On appelle l'ensemble de ce genre d'information *environnement* (env).

On ajoute des données d'informations à env pour qu'il existe une façon unique de mettre à jour env. On propose la définition de env suivant:

```ocaml
type scope = Cond of bool option | Def of name option*int*element list | Call
type sdico = (scope*dico) list
type env = stack*sdico
```

stack représente la pile globale, un sdico est une pile de dictionnaires qui enregistrent les définitions de fonction dans chaque scope. On tient aussi quelques informations spéficiques aux scopes.

```
* scope conditionel
Cond of bool option

Some true : on est en IF ... ou ELSE ... effectifs;
Some false : on est en IF ... ou ELSE ... non-effectifs;
None : on est dans un conditionnel qui est dans un conditionnel non effectif.

* scope défnition de fonction
Def of name option*int*element list

Le nom du fonction (option car on ne le sait pas en recevant :); une liste d'élément qui enregistre le programme de cette fonction.

* scope d'exécution globale ou d'une fonction
Call
```

Le mis à jour de env par application d'un élément est naturel. En pratique, pour minimiser la duplication de code, on traite les cas effectif dans ```eval_prog```, les cas ```step```, si l'une des 2 reçoit un cas contraire, elle passe la tâche à l'autre.

Complexité temporelle : O(1) pour l'application d'un élément sauf que les appels de fonction.

## Mode d'emploi

C'est un projet organisé avec dune. On peut soit utiliser les commandes dune

```
dune build
dune run
dune test
...
```

ou des lignes de commandes.

### Compilation

```shell
opam install . --deps-only # pour installer les dépendances
make # compiler
```  

### Installation

```shell
> opam switch create . --empty # to create a local swtich
> eval $(opam env) # to load the new switch
> opam install . # to install from source#
```

### Utilisation

Après l'installation:

```shell
$ pf23
pf23> 42
42
```

ou après la compilation: ```make run```

### Test

1. Installer ppx_inline_test ```opam install ppx_inline_test.v0.14.1```;
2. ```make test```

ou tester avec utop (pour afficher plus de détailes il faut modifier les interfaces)

```ocaml
$ dune utop
utop # Pf23.(eval_prog env (parse "1 2 3 > IF -1 ELSE :"));;
- : Pf23.env =
([Pf23.N 1],
 [(Pf23.Def (None, 0, []), <abstr>); (Pf23.Cond (Some true), <abstr>);
  (Pf23.Call, <abstr>)])
```