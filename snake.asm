row equ 24
col equ 80
data segment

    snakeX db 50 dup(?)
    snakeY db 50 dup(?)
    x db 40
    y db 12
    snakeCount db 4
    current db 'B' ; b => bottom , u => up , l => left , r => right
    fruitY db 8
    fruitX db 8
    msg db 'YOU LOST$'
    score db "SCORE : $"

data ends

code segment

    assume cs:code,ds:data

    changeCursor proc ;move x to dl and y to dh befor use
        
        mov bh,0
        mov ah,2
        int 10h
        ret 

    changeCursor endp

    drawChar proc ;move char to al before use
        push cx ; saving last value of cx
        mov bh,0 ; page number
        mov bl,0fh ; char color
        mov cx,1 ; loop count
        mov ah,0ah 
        int 10h
        pop cx ; return cx value to what is used to be
        ret

    drawChar endp
    
    getSnakeX proc
        
        mov si,offset snakeX
        add si,cx
        mov al,[si]
        ret

    getSnakeX endp

    getSnakeY proc
        
        mov si,offset snakeY
        add si,cx
        mov ah,[si]
        ret

    getSnakeY endp

    
    addPartToSnake proc

        cmp current,'L'
        je right
        cmp current,'R'
        je left
        cmp current,'U'
        je bottom
        cmp current, 'B'
        je up

        right: ; x - 1

            xor cx,cx
            mov cl,snakeCount
            dec cl
            call getSnakeX ; al = x
            dec al
            inc si
            mov [si],al
            call getSnakeY ; ah = y
            inc si
            mov [si],ah
            jmp endProc

        left: ; x + 1

            xor cx,cx
            mov cl,snakeCount
            dec cl
            call getSnakeX ; al = x
            inc al
            inc si
            mov [si],al
            call getSnakeY ; ah = y
            inc si
            mov [si],ah
            jmp endProc
        
        up: ; y - 1

            xor cx,cx
            mov cl,snakeCount
            dec cl
            call getSnakeX ; al = x
            inc si
            mov [si],al
            call getSnakeY ; ah = y
            dec ah
            inc si
            mov [si],ah
            jmp endProc

        bottom: ; y + 1

            xor cx,cx
            mov cl,snakeCount
            dec cl
            call getSnakeX ; al = x
            inc si
            mov [si],al
            call getSnakeY ; ah = y
            inc ah
            inc si
            mov [si],ah
            jmp endProc
        
        endProc:

            inc snakeCount
            ret
        
    addPartToSnake endp
    
    
    drawSnake proc
        ; 1 - draw new point
        ; 2 - delete last point
        ; 3 - change x,y

        getNewPointXY:

            cmp current,'L'
            je  moveToLeft
            cmp current,'R'
            je  moveToRight
            cmp current,'U'
            je  moveToUp
            cmp current,'B'
            je  moveToBottom

        moveToLeft:
            
            mov cl,0
            call getSnakeY
            mov y, ah
            call getSnakeX
            mov x, al
            dec x
            jz setXToMax
            jmp drawNewPoint
        
        setXToMax:

            mov x,79
            jmp drawNewPoint

        moveToRight:
            
            mov cl,0
            call getSnakeY
            mov y, ah
            call getSnakeX
            mov x, al
            inc x
            cmp x,79
            jge setXToO ; if snake goes of out boundry
            jmp drawNewPoint

        setXToO:

            mov x,0
            jmp drawNewPoint

        moveToUp:

            mov cl,0
            call getSnakeX
            mov x, al
            call getSnakeY
            mov y, ah
            dec y
            jz setYToMax ; if snake goes of out boundry
            jmp drawNewPoint

        setYToMax:

            mov y,24
            jmp drawNewPoint

        moveToBottom:

            mov cl,0
            call getSnakeX
            mov x, al
            call getSnakeY
            mov y, ah
            inc y
            cmp y,24
            jge setYToO ; if snake goes of out boundry
            jmp drawNewPoint
        
        setYToO:
            
            mov y,0
            jmp drawNewPoint

        drawNewPoint:
           
            ; operations for this label
            mov dl,x
            mov dh,y
            call changeCursor
            call readCharAt
            cmp al,'O'
            je colidedWithFruit
            cmp al,'*'
            je endGame
            mov al,'*'
            call drawChar
            jmp deleteLastPoint

        colidedWithFruit:
            call addPartToSnake
            push dx
            call generateNewFruit
            pop dx
            call changeCursor
            mov al,'*'
            call drawChar
            jmp deleteLastPoint
        
        endGame:
            mov ax,3
            int 10h
            mov ah,09h
            lea dx,msg
            int 21h
            
            mov ah,4ch
            int 21h  

        deleteLastPoint:

            mov cx,0 ; set cx as counter
            mov cl,snakeCount ; our array length is snakeCount => n = snakeCount
            dec cl ; array count is 0 to n - 1
            call getSnakeX
            mov dl,al
            call getSnakeY
            mov dh,ah
            call changeCursor
            mov al, ' '
            call drawChar
            jmp getNewPoint

        getNewPoint:
            mov cx,0
            ; operations for this label
            call getSnakeX ; al = snakeX[cl] ,  [si] => snakeX[cl]
            mov bl,x
            mov [si],bl
            call getSnakeY ; ah = snakeX[cl] ,  [si] => snakeY[cl]
            mov bh,y
            mov [si],bh
            mov bx,ax
            ; setups for next label
            inc cx
            jmp changeXY

        changeXY:
            
            call getSnakeX ; al = snakeX[cl] ,  [si] => snakeX[cl]
            mov [si],bl ; bl = snakeX[cl-1] => snakeX[cl] = snakeX[cl-1] 
            mov bl,al ; bl = snakeX[cl]
            call getSnakeY ; ah = snakeX[cl] ,  [si] => snakeY[cl]
            mov [si],bh ; bh = snakeY[cl-1] => snakeY[cl] = snakeY[cl-1] 
            mov bh,ah ; bh = snakeY[cl]
            inc cl
            
            cmp cl,snakeCount
            jl changeXY 

        ret

    drawSnake endp

    delay proc 
        
        mov ah, 00
        int 1Ah
        mov bx, dx
    
        jmp_delay:

            int 1Ah
            sub dx, bx
            ;there are about 18 ticks in a second, 10 ticks are about enough
            cmp dl, 5                                                      
            jl jmp_delay    
            ret

    delay endp

    readchar proc

        mov ah, 01H
        int 16H
        jnz keybdpressed
        xor dl, dl
        ret

        keybdpressed:

            ;extract the keystroke from the buffer
            mov ah, 00H
            int 16H
            mov dl,al
            ret

    readchar endp                    

    changeCurrent proc

        call readChar
        cmp dl, 0
        jnz exit
        cmp ah,48h
        je upPressed
        cmp ah,50h
        je bottomPressed
        cmp ah,4bh
        je leftPressed
        cmp ah,4dh
        je rightPressed
        ret
        rightPressed:

            cmp current,'L'
            je exit
            mov current,'R'
            ret

        leftPressed:

            cmp current,'R'
            je exit
            mov current,'L'
            ret

        upPressed:

            cmp current,'B'
            je exit
            mov current,'U'
            ret

        bottomPressed:
        
            cmp current,'U'
            je exit
            mov current,'B'
            ret
        
        exit:
            ret
        ret

    changeCurrent endp

    generateNewFruit proc

        generate:
            mov cl,fruitX
            mov ch,fruitY
            mov ah, 00 ; gets SystemTime
            int 1Ah
            ;dx contains the ticks
            push dx ; pushing dx to use later to getX with same systemTime
            mov ax, dx ; moving dx to ax to use DIV ins later 
            xor dx, dx ; dx => 0
            xor bh, bh ; bh => 0
            mov bl, row ; random number will be generated in range 0 - row 
            dec bl ; row - 1 
            div bx
            mov fruity, dl
            inc fruity

            pop ax
            mov bl, col
            dec dl
            xor bh, bh
            xor dx, dx
            div bx
            mov fruitx, dl
            inc fruitx
            cmp cl,fruitX
            je generate
            cmp ch,fruitY
            je generate

        checkCollision:

            mov dl,fruitX
            mov dh,fruitY
            call changeCursor
            call readCharAt
            cmp al,'*'
            je generate 

        drawFruit:
            mov dl,fruitX
            mov dh,fruitY
            call changeCurrent
            mov al,'O'
            call drawChar

        ret

    generateNewFruit endp

    readCharAt proc ; change cursor pos before use this
        mov ax,0
        mov bh,0
        mov ah,08
        int 10h
        ret

    readCharAt endp

    ;dl x,dh y
    start:
        
        ; introducing variables to program
        mov ax,data
        mov ds,ax

        mov bl,x ; snake Head X
        mov bh,y ; snake Head Y
        xor cx,cx ; cx => 0
        setSnakeFirstPosition:

            setX:

                mov si,offset snakeX
                add si,cx
                mov [si],bl
                inc bl
                inc cl
                cmp cl,snakeCount
                jle setX
                xor cx,cx
            
            setY:

                mov si,offset snakeY
                add si,cx
                mov [si],bh
                
                inc cl
                cmp cl,snakeCount
                jle setY

        xor cx,cx

        drawSnakeFirstPosition:

            call getSnakeX
            mov dl,al
            call getSnakeY
            mov dh,ah
            inc cl
            mov al,'*'
            call changeCursor
            call drawChar
            cmp cl,snakeCount
            jl drawSnakeFirstPosition
        
        drawFirstFruit:
            call generateNewFruit
        
        draw:

            call changeCurrent
            
            call delay
            
            call drawSnake

            jmp draw
        
    end start

code ends
