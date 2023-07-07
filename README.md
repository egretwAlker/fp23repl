# Pf23REPL

## Pf23

Pf23 est un langage conçu par Monsieur Emmanuel Chailloux à une data inconnue pour l'UE LU2IN119 été-2023 qui ressembler à PostScript.

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
<id>   ::= une suite de char qui n'est pas un élément spécial défini dessus
```

## Sémantique

(c.f. LU2IN119.pdf)

Un ```<expr>``` peut s'appliquer à une pile et soit produire une erreur, soit retourner
une pile de résultat.

L'ensemble des expressions sans erreur d'exécution en s'appliquant à une pile vide est le langage de Pf23.

Le suivant est les effets de quelques expressions sur des piles; l'effet d'une expression quelconque est la composition des effets décrits dessous.

```
Description de l'effet une opérateur : op (pile -- nouvelle pile)

opérateurs de pile
- DUP  (n -- n n)         (dupliquer le sommet de pile)
- DROP ( n -- )           (supprimer le sommet de pile)
- SWAP ( a b -- b a)      (échanger des deux éléments du sommet)
- ROT  ( a b c -- b c a)  (rotation des trois éléments du sommet)

opérateurs arithmétiques et de comparaison
- *, /,+,- (a b -- b op a ) b op a dénote un entier.
- =,<>,<,> (a b -- b op a ) b op a dénote un booléen (TRUE ou FALSE).

<dec> définit une fonction qui pourra être appelée par <id>  
<cond> s'exécute de manière dépendante de la tête booléenne de la pile (IF supprime la tête)
```

Les imbrications des fonctions et des conditionnelles sont possible. ```IF ... THEN``` crée une portée de variables à l'intérieur ainsi comme ```: fn ... ;``` . L'accès des vairables se fait lors de l'exécution de fonction au lieu de définition de fonction.

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

Donc le programme a besoin de savoir au moins 1. le stack actuel; 2. si l'on est en état effectif ou non (dans un milieu d'une définition de fonction ou une branche de if non effective); 3. des dictionnaires pour des portées pilées. On appelle l'ensemble de ce genre d'information *environnement* (env).

On ajoute des données d'informations à env pour que

Totally interactive

pretty print

trace failure?

Time complexity :

On souhaite pouvoir réaliser:  
On a un stack (vide initialement). À chaque fois on passe un élément et on met à jour le stack qui
correspond à l'exécution de la suite des éléments passées (qui est un préfixe d'une expression).

Avec une suite d'éléments et un stack, on passe un autre élément, ce que passe pour le stack
est la seuele chose l'interpreteur retourne à l'utilisateur. 

Le principe de l'évalutation consiste à mettre à jour l'env à chaque élément.
Un env consiste en un stack sur lequel on opère,
une pile de (scope*dico) qui mémorise la hiérachie de l'exécution
(e.g. If ... If (Id fn) Then ... Then, quand on exécution la fonction fn, on aura l'hiérarchie Call::Cond::Cond::Call::[]),
où chaque élément et un registrement d'une description de scope et la dictionnaire associée à ce scope

Les descriptions des scopes:
Pour Call, pas de descriptions supplémentaires. Pour Cond, avant de rentrer ce scope, 

Un env est soit en état effective, soit en état non effective (c.f. la commentaire de [effective]).

Pour le developpeur,
[eval_prog] traite des cas en état effective sinon il passe la tâche à [step].
[step] traite des cas en état non effective sinon il passe la tâche à [eval_prog].
C'est pour minimiser la duplication de code.
Pour l'utilisateur, la différence des 2 est seuelement l'un applique les éléments dans une liste, l'autre applique un élément.