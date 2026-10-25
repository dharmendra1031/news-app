'use client'
import { useEffect } from 'react'
import { useEditor, EditorContent, type Editor } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import Underline from '@tiptap/extension-underline'
import Link from '@tiptap/extension-link'
import { Bold, Italic, Underline as UnderlineIcon, Link as LinkIcon, List, ListOrdered, RemoveFormatting } from 'lucide-react'

const HEADING_OPTIONS = [
    { label: 'Normal', value: 'paragraph' },
    { label: 'Heading 1', value: 'h1' },
    { label: 'Heading 2', value: 'h2' },
    { label: 'Heading 3', value: 'h3' },
    { label: 'Heading 4', value: 'h4' },
]

const getHeadingValue = (editor: Editor) => {
    for (let i = 1; i <= 4; i++) {
        if (editor.isActive('heading', { level: i })) return `h${i}`
    }
    return 'paragraph'
}

const applyHeadingValue = (editor: Editor, value: string) => {
    if (value === 'paragraph') {
        editor.chain().focus().setParagraph().run()
    } else {
        editor.chain().focus().setHeading({ level: parseInt(value[1]) as 1 | 2 | 3 | 4 }).run()
    }
}

interface ToolBtnProps {
    onClick: () => void
    active?: boolean
    disabled?: boolean
    children: React.ReactNode
    title: string
}

const ToolBtn = ({ onClick, active, disabled, children, title }: ToolBtnProps) => (
    <button
        type='button'
        title={title}
        onClick={onClick}
        disabled={disabled}
        className={`flex items-center justify-center w-7 h-7 rounded transition-colors
            ${active ? 'bg-gray-200 dark:bg-gray-600 text-gray-900 dark:text-white' : 'text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'}
            disabled:opacity-30 disabled:cursor-not-allowed`}
    >
        {children}
    </button>
)

const Divider = () => <span className='w-px h-5 bg-gray-300 dark:bg-gray-600 mx-0.5 self-center' />

const MenuBar = ({ editor }: { editor: Editor | null }) => {
    if (!editor) return null

    const handleLink = () => {
        const prev = editor.getAttributes('link').href
        const url = window.prompt('URL', prev || 'https://')
        if (url === null) return
        if (url === '') {
            editor.chain().focus().unsetLink().run()
        } else {
            editor.chain().focus().setLink({ href: url }).run()
        }
    }

    return (
        <div className='flex items-center flex-wrap gap-0.5 px-2 py-1.5 border-b borderColor bg-gray-50 dark:bg-gray-800'>
            <div className='relative flex items-center me-1'>
                <select
                    value={getHeadingValue(editor)}
                    onChange={(e) => applyHeadingValue(editor, e.target.value)}
                    className='appearance-none text-sm text-gray-700 dark:text-gray-200 bg-transparent pl-1 pr-5 py-0.5 rounded cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 focus:outline-none'
                >
                    {HEADING_OPTIONS.map((o) => (
                        <option key={o.value} value={o.value}>{o.label}</option>
                    ))}
                </select>
            </div>

            <Divider />

            <ToolBtn title='Bold' onClick={() => editor.chain().focus().toggleBold().run()} active={editor.isActive('bold')}>
                <Bold size={14} strokeWidth={2.5} />
            </ToolBtn>
            <ToolBtn title='Italic' onClick={() => editor.chain().focus().toggleItalic().run()} active={editor.isActive('italic')}>
                <Italic size={14} strokeWidth={2.5} />
            </ToolBtn>
            <ToolBtn title='Underline' onClick={() => editor.chain().focus().toggleUnderline().run()} active={editor.isActive('underline')}>
                <UnderlineIcon size={14} strokeWidth={2.5} />
            </ToolBtn>
            <ToolBtn title='Link' onClick={handleLink} active={editor.isActive('link')}>
                <LinkIcon size={14} strokeWidth={2.5} />
            </ToolBtn>

            <Divider />

            <ToolBtn title='Ordered list' onClick={() => editor.chain().focus().toggleOrderedList().run()} active={editor.isActive('orderedList')}>
                <ListOrdered size={14} strokeWidth={2.5} />
            </ToolBtn>
            <ToolBtn title='Bullet list' onClick={() => editor.chain().focus().toggleBulletList().run()} active={editor.isActive('bulletList')}>
                <List size={14} strokeWidth={2.5} />
            </ToolBtn>

            <Divider />

            <ToolBtn title='Clear formatting' onClick={() => editor.chain().focus().clearNodes().unsetAllMarks().run()}>
                <RemoveFormatting size={14} strokeWidth={2.5} />
            </ToolBtn>
        </div>
    )
}

interface TipTapEditorProps {
    value: string
    onChange: (html: string) => void
}

const TipTapEditor = ({ value, onChange }: TipTapEditorProps) => {
    const editor = useEditor({
        extensions: [StarterKit, Underline, Link.configure({ openOnClick: false })],
        content: value || '',
        immediatelyRender: false,
        onUpdate: ({ editor }) => {
            onChange(editor.getHTML())
        },
    })

    useEffect(() => {
        if (!editor || editor.isDestroyed) return
        if (value !== editor.getHTML()) {
            editor.commands.setContent(value || '', { emitUpdate: false })
        }
    }, [value, editor])

    return (
        <div className='border borderColor rounded-[6px] overflow-hidden'>
            <MenuBar editor={editor} />
            <EditorContent
                editor={editor}
                className="[&_.ProseMirror]:min-h-[200px] [&_.ProseMirror]:p-3 [&_.ProseMirror]:outline-none
                    [&_.ProseMirror_h1]:text-3xl [&_.ProseMirror_h1]:font-bold [&_.ProseMirror_h1]:mb-2
                    [&_.ProseMirror_h2]:text-2xl [&_.ProseMirror_h2]:font-bold [&_.ProseMirror_h2]:mb-2
                    [&_.ProseMirror_h3]:text-xl [&_.ProseMirror_h3]:font-bold [&_.ProseMirror_h3]:mb-1
                    [&_.ProseMirror_h4]:text-lg [&_.ProseMirror_h4]:font-bold [&_.ProseMirror_h4]:mb-1
                    [&_.ProseMirror_ul]:list-disc [&_.ProseMirror_ul]:pl-5
                    [&_.ProseMirror_ol]:list-decimal [&_.ProseMirror_ol]:pl-5
                    [&_.ProseMirror_a]:text-blue-500 [&_.ProseMirror_a]:underline"
            />
        </div>
    )
}

export default TipTapEditor
