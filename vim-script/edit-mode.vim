" ----------------------------------------------------------
" Edit Mode Change(Tab-8 or Space-4)
" ----------------------------------------------------------
let s:space_list = [
    \'vim',
    \'yaml',
    \'scheme',
    \'python',
    \'markdown',
    \'gitcommit',
    \'matlab',
\]

let s:current_edit_mode = "Tab" " default with Tab

function! EditWithTab()
    set ts=8
    set st=8
    set shiftwidth=8
    set softtabstop=8
    set noexpandtab
    set autoindent
    set smartindent
    let s:current_edit_mode = "Tab"
endfunction

function! EditWithSpace()
    set ts=4
    set st=4
    set shiftwidth=4
    set softtabstop=4
    set expandtab
    set autoindent
    set smartindent
    let s:current_edit_mode = "Space"
endfunction

function! EditWithAnother()
    if s:current_edit_mode == "Space"
        call EditWithTab()
    else
        call EditWithSpace()
    endif
endfunction

function! EditMode()
    echo "CurrentEditMode: " . s:current_edit_mode
endfunction

let s:FiletypeConfig = {}
function s:FiletypeConfig.getEditMode(type) dict
    return get(self, a:type, "Tab")
endfunction

for key in s:space_list
    let s:FiletypeConfig[key] = "Space"
endfor

function EditWithFiletype()
    if s:current_edit_mode != s:FiletypeConfig.getEditMode(&filetype)
        call EditWithAnother()
    endif
endfunction

" --------------------------------------
" auto detection & key map
auto BufNew * call EditWithFiletype()
auto BufNewFile * call EditWithFiletype()
auto BufRead * call EditWithFiletype()

map <Bslash> :call EditWithAnother()<CR>:call EditMode()<CR>
