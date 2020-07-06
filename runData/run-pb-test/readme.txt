classical-poll : runs on all of the 25 problems with seed = 1..5 in dimension 2 4 8 16 32 64 with classical poll

dynamic : runs on all of the 25 problems with seed = 1..5 in dimension 2 4 8 16 32 64 with oignon and enriched poll, max number of 2n blocks are set to 2 4 8 16 32 64 : at each poll step a possibly changing number of directions is generated, based on previous success and failure.

static : runs on all of the 25 problems with seed = 1..5 in dimension 2 4 8 16 32 64 with oignon and enriched poll, number of 2n blocks are set to 2 4 8 16 32 64 : at each poll step a constant number of direction is generated 

compareGeometry : runs on all of the 25 problems with seed = 1..5 in dimension 2 4 8 16 32 64 and strategies multi, oignon and enriched, made with the same static number of points : 2n+1




../LHS			: LHS sampling of [-5,5]^n with the equivalent nb of points generated with classical poll made with 500 iterations.
../classical-poll	: runs with classical poll		|| DONE
../static		: runs static oignon and enriched	|| TODO : finir en dim 64
../compareGeometry	: runs static multi oignon and enriched || TODO : finir en dim 64
../dynamic		: runs dynamic oignon and enriched 
      |-with-memory
	     |-lin	:	|| TODO : finir en dim 64
	     |-exp	:	|| TODO : finir en dim 64
      |-without-memory
	     |-lin	:	|| DONE
	     |-exp	:	|| TODO : finir en dim 64
../enriched-on-frame-static 	: runs with enriched strategie generating points exactly on the frame (a=b=1)
