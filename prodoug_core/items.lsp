{
	[[0x10]] 0x8bffd298a64ee36eb7b99dcc00d2c67259d15c60;Doug Address
	
	; Add the starter stuff.
	[0x0] "Cardboard Box"
	[[@0x0]] "misc" ; Category
	[[(- @0x0 1)]] 1; Max stack size.
	[[(- @0x0 2)]] 0
	[[(- @0x0 3)]] @@0x10
	[[(- @0x0 4)]] (TIMESTAMP)
	
	[0x20] "3-wheeled Shopping Cart"
	[[@0x20]] "misc"
	[[(- @0x20 1)]] @@0x10
	[[(- @0x0 2)]] 0
	[[(- @0x0 3)]] @@0x10
	[[(- @0x0 4)]] (TIMESTAMP)
	
	[[0x11]] 2
	[[0x12]] @0x0
	[[0x13]] @0x20
	
	[[(+ @0x0 2)]] @0x20
	[[(+ @0x20 1)]] @0x0
	
	[0x0] "reg"
	[0x20] "items"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20) ;Register with DOUG TODO remove after beta
	
	;body section
	[0x0](LLL
		{				
			[0x0] (calldataload 0)
			[0x20] (calldataload 32)
			
			; USAGE: 0: "getitem" 32: "name"
			; RETURNS: Pointer to the item with name "name", or null.
			; INTERFACE: Items
			(when (= @0x0 "getitem")
				{
					; Don't let caller access the reserved addresses.
					(unless (> @0x20 0x40)
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					[0x0] @@ (calldataload 32)
					(return 0x0 32)
				}
			)
			
			; USAGE: 0: "getitemfull" 32: "name"
			; RETURNS: type:stacksize:address:owner:timestamp.
			; INTERFACE: Items
			(when (= @0x0 "getitemfull")
				{
					; Don't let caller access the reserved addresses.
					(unless (> @0x20 0x40)
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					[0x0] @@ (calldataload 32)
					
					(unless @0x0 (return 0x0 32))
					
					[0x20] @@(- (calldataload 32) 1)
					[0x40] @@(- (calldataload 32) 2)
					[0x60] @@(- (calldataload 32) 3)
					[0x80] @@(- (calldataload 32) 4)
					(return 0x0 160)
				}
			)
			
			[0x40] (calldataload 64)
			
			; USAGE: 0: "registeritem" 32: "name", 64: type, 96: maxstacksize, 128 : address, 160 : creator address
			; RETURNS: 1 if success, 0 if fail.
			; INTERFACE Items
			(when (= @0x0 "registeritem")
				{
					; Don't let caller access the reserved addresses.
					(unless (> @0x20 0x40)
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					;If the item already exists - cancel.
					(when @@ @0x20 
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					[0x60] "get"
					[0x80] "actions"
					(call (- (GAS) 100) @@0x10 0 0x60 64 0xA0 32) ; Check if there is a votes contract.
														
					(when @0xA0 ; If so, validate the caller to make sure it's a proper action.
						{
							[0x60] "validate"
							[0x80] (CALLER)
							(call (- (GAS) 100) @0xA0 0 0x60 64 0x60 32)
					
							(unless @0x60 (return 0x60 32) )	
						}
					)
					
					;Store type at name.
					[[@0x20]] @0x40
					[[(- @0x20 1)]] (calldataload 96)  ; maxstacksize
					[[(- @0x20 2)]] (calldataload 128) ; address
					[[(- @0x20 3)]] (calldataload 160) ; owner
					[[(- @0x20 4)]] (TIMESTAMP)
		
					(if @@0x11 ; If there are elements in the list. 
						{
							;Update the list. First set the 'next' of the current head to be this one.
							[[(+ @@0x13 2)]] @0x20
							;Now set the current head as this ones 'previous'.
							[[(+ @0x20 1)]] @@0x13	
						} 
						{
							;If no elements, add this as tail
							[[0x12]] @0x20
						}
					
					)
					
					;And set this as the new head.
					[[0x13]] @0x20
					;Increase the list size by one.
					[[0x11]] (+ @@0x11 1)
					
					;Return the value 1 for a successful register
					[0x0] 1
					(return 0x0 0x20)
				} ;end body of when
			); end when
			
			; USAGE: 0: "removeitem" 32: "name"
			; RETURNS: 1 if success, 0 if fail.
			; INTERFACE Items
			(when (= @0x0 "removeitem")
				{
					; Don't let caller access the reserved addresses.
					(unless (> @0x20 0x40)
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					;If the name has no address (does not exist) - cancel.
					[0x40] @@ @0x20
					(unless @0x40 
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					[0x60] "get"
					[0x80] "actions"
					(call (- (GAS) 100) @@0x10 0 0x60 64 0xA0 32) ; Check if there is a votes contract.
					
					(when @0xA0 ; If so, validate the caller to make sure it's a proper action.
						{	
							[0x60] "validate"
							[0x80] (CALLER)
							(call (- (GAS) 100) @0xA0 0 0x60 64 0x60 32)
					
							(unless @0x60 (return 0x60 32) )		
						}
					)
		
					[0x40] @@(+ @0x20 1) ; Here we store the this ones 'previous' (which always exists).
					[0x60] @@(+ @0x20 2) ; And next
				
					;Change previous elements 'next' to this ones 'next', if this one has a next (this could be the head..)
					(if @0x60
						{
							(if @0x40
								{
									;Change next elements 'previous' to this ones 'previous'.
									[[(+ @0x60 1)]] @0x40
									;Change previous elements 'next' to this ones 'next'.
									[[(+ @0x40 2)]] @0x60		
								}
								{
									; We are tail. Set next elements previous to 0
									[[(+ @0x60 1)]] 0
									; Set next element as current tail.
									[[0x12]] @0x60
								}
								
							)
						}
						
						{
							(if @0x40
								{
									;This element is the head - unset 'next' for the previous element making it the head.
									[[(+ @0x40 2)]] 0
									;Set previous as head
									[[0x13]] @0x40	
								}
								{
									; This element is the tail. Reset head and tail.
									[[0x12]] 0
									[[0x13]] 0
								}					
							)
						}
					)
		
					;Now clear out this element and all its associated data.
					
					[[@0x20]] 0			;The address of the name-type
					[[(+ @0x20 1)]] 0	;The address for its 'previous'
					[[(+ @0x20 2)]] 0	;The address for its 'next'
					[[(- @0x20 1)]] 0	;The address for its maxstacksize
					[[(- @0x20 2)]] 0	;The address for its optional contract address
					[[(- @0x20 3)]] 0	;The creator address
					[[(- @0x20 4)]] 0	;The timestamp
					
					;Decrease the size counter
					[[0x11]] (- @@0x11 1)
					[0x0] 1
					(return 0x0 32)
				} ; end when body
			) ;end when
												
			; USAGE: 0 : "kill"
			; RETURNS: 0 if fail.
			; NOTES: Suicide the contract if 'doug' is the calling contract.
			(when (= (calldataload 0) "kill")
				{
					(unless (= (CALLER) @@0x10) 
						{
							[0x0] 0
							(return 0x0 32)
						}
					)
					
					(suicide (CALLER))
				}
			)
			
			[0x0] 0
			(return 0x0 32)
					
		} 0x20 )
	(return 0x20 @0x0) ;Return body
}