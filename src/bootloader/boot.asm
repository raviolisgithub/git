org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

jmp short start
nop

bdb_oem:                         db 'MSWIN4.1'
bdb_bytes_per_sector:            dw 512
bdb_sectors_per_cluster:         db 1
bdb_reserved_sectors:            dw 1
bdb_fat_count:                   db 2
bdb_dir_entries_count:           dw 0E0h
bdb_total_sectors:               dw 2880
bdb_meadia_descriptor_type:      db 0F0h
bdb_sectors_per_fat:             dw 9
bdb_sectors_per_track:           dw 18
bdb_heads:                       dw 2
bdb_hidden_sectors:              dd 0
bdb_large_sector_count:          dd 0

ehr_drive_number:                db 0
                                 db 0
ehr_signature:                   db 29h
ehr_volume_id:                   db 12h, 34h, 56h, 78h
ehr_volume_label:                db 'RAVIOLI OS'
ehr_system_id:                   db 'FAT12  '

start:
    jmp main

puts:
    push si
    push ax

.loop:
    lodsb
    cmp al, 0
    je .done
    mov bh, 0
    mov ah, 0x0e
    int 0x10
    jmp .loop

.done:
    pop ax
    pop si
    ret
main:

    mov ax, 0
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00

    mov [ehr_drive_number], dl

    mov ax, 1
    mov cl, 1
    mov bx, 0x7E00
    call disk_read

    mov si, msg_hello
    call puts 

    hlt

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0

.halt:
    cli
    hlt



lba_to_chs:

    push ax
    push dx

    xor dx, dx
    div word [bdb_sectors_per_track]


    inc dx
    mov cx, dx

    xor dx, dx
    div word [bdb_heads]

    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax
    ret


disk_read:
    
    push ax
    push bx
    push cx
    push dx
    push di


    push cx
    call lba_to_chs
    pop ax

    mov ah, 02h
    mov di, 3
.retry:
    pusha
    stc
    int 13h
    jnc .done

    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa

    push di
    push dx
    push cx
    push bx
    push ax
    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


msg_hello: db 'Hello, world!', 0
msg_read_failed:    db 'Reading the disk failed. RAVIOLI-OS ERR1'

times 510-($-$$) db 0
dw 0AA55h