'use client';
import { useEffect, useRef, useState } from 'react';
import { FaAnglesLeft, FaAnglesRight, FaChevronLeft, FaChevronRight } from 'react-icons/fa6';
import { MdOutlineFirstPage, MdOutlineLastPage, MdZoomIn, MdZoomOut } from 'react-icons/md';
import LoadMoreSpinner from '@/components/common/loadermoreBtn/LoaderSpinner';

const PDFJS_CDN = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.4.168/pdf.min.mjs';
const WORKER_CDN = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.4.168/pdf.worker.min.mjs';

interface PdfPage {
    getViewport: (params: { scale: number }) => { width: number; height: number };
    render: (params: { canvasContext: CanvasRenderingContext2D; viewport: unknown }) => { promise: Promise<void>; cancel: () => void };
}

interface PdfDocument {
    numPages: number;
    getPage: (pageNumber: number) => Promise<PdfPage>;
}

interface PdfJsLib {
    GlobalWorkerOptions: { workerSrc: string };
    getDocument: (src: string) => { promise: Promise<PdfDocument> };
}

interface PdfViewerProps {
    pdf: string;
    onClose: () => void;
}

const PdfViewer = ({ pdf, onClose }: PdfViewerProps) => {
    const canvasRef = useRef<HTMLCanvasElement>(null);
    const [pdfDoc, setPdfDoc] = useState<PdfDocument | null>(null);
    const [pageNumber, setPageNumber] = useState(1);
    const [numPages, setNumPages] = useState(0);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [scale, setScale] = useState(1);
    const renderTaskRef = useRef<{ promise: Promise<void>; cancel: () => void } | null>(null);

    const MIN_SCALE = 0.5;
    const MAX_SCALE = 4.0;
    const SCALE_STEP = 0.2;
    const zoomIn = () => setScale((s) => Math.min(MAX_SCALE, +((s + SCALE_STEP).toFixed(1))));
    const zoomOut = () => setScale((s) => Math.max(MIN_SCALE, +((s - SCALE_STEP).toFixed(1))));
    const zoomReset = () => setScale(1.4);

    // Load PDF.js + document
    useEffect(() => {
        let cancelled = false;
        const load = async () => {
            try {
                setLoading(true);
                setError(null);
                const lib: PdfJsLib = await import(/* webpackIgnore: true */ PDFJS_CDN);
                lib.GlobalWorkerOptions.workerSrc = WORKER_CDN;
                const doc = await lib.getDocument(pdf).promise;
                if (cancelled) return;
                setPdfDoc(doc);
                setNumPages(doc.numPages);
                setPageNumber(1);
            } catch (e) {
                if (!cancelled) setError('Failed to load PDF. ' + (e as Error)?.message);
            } finally {
                if (!cancelled) setLoading(false);
            }
        };
        load();
        return () => { cancelled = true; };
    }, [pdf]);

    // Render current page
    useEffect(() => {
        if (!pdfDoc || !canvasRef.current) return;
        const render = async () => {
            try {
                if (renderTaskRef.current) {
                    renderTaskRef.current.cancel();
                    renderTaskRef.current = null;
                }
                const page = await pdfDoc.getPage(pageNumber);
                const viewport = page.getViewport({ scale });
                const canvas = canvasRef.current;
                if (!canvas) return;
                canvas.height = viewport.height;
                canvas.width = viewport.width;
                const context = canvas.getContext('2d');
                if (!context) return;
                const task = page.render({ canvasContext: context, viewport });
                renderTaskRef.current = task;
                await task.promise;
                renderTaskRef.current = null;
            } catch (e) {
                const err = e as { name?: string; message?: string };
                if (err?.name !== 'RenderingCancelledException') setError(err?.message ?? 'Failed to render page.');
            }
        };
        render();
    }, [pdfDoc, pageNumber, scale]);

    // Lock body scroll while viewer open
    useEffect(() => {
        document.body.style.overflow = 'hidden';
        return () => { document.body.style.overflow = ''; };
    }, []);

    // Close on Escape
    useEffect(() => {
        const handler = (e: KeyboardEvent) => e.key === 'Escape' && onClose?.();
        window.addEventListener('keydown', handler);
        return () => window.removeEventListener('keydown', handler);
    }, [onClose]);

    const goFirst = () => setPageNumber(1);
    const goLast = () => setPageNumber(numPages);
    const goPrev = () => setPageNumber((p) => Math.max(1, p - 1));
    const goNext = () => setPageNumber((p) => Math.min(numPages, p + 1));

    // Visible page buttons around current page
    const getPageButtons = () => {
        const range = [];
        const start = Math.max(1, pageNumber - 2);
        const end = Math.min(numPages, start + 4);
        for (let i = start; i <= end; i++) range.push(i);
        return range;
    };

    const NavBtn = ({ onClick, disabled, children, active }: { onClick: () => void; disabled?: boolean; children: React.ReactNode; active?: boolean }) => (
        <button
            onClick={onClick}
            disabled={disabled}
            className={`min-w-[28px] h-7 px-1.5 rounded text-sm font-semibold transition-all
        ${active
                    ? 'bg-white text-gray-900'
                    : 'text-gray-200 hover:text-white hover:bg-white/20 disabled:opacity-30 disabled:cursor-not-allowed'
                }`}
        >
            {children}
        </button>
    );

    return (
        /* Backdrop */
        <div
            className="fixed inset-0 z-50 flexColumnCenter w-full"
            style={{ backgroundColor: 'rgba(0,0,0,0.82)' }}
        >
            {/* Left dark panel */}
            <div className="absolute inset-y-0 left-4 flexCenter">
                <button
                    onClick={goPrev}
                    disabled={pageNumber <= 1}
                    className="w-10 h-10 rounded-full bg-white/10 hover:bg-white/25 disabled:opacity-20 disabled:cursor-not-allowed flexCenter text-white text-xl transition"
                >
                    <FaChevronLeft />
                </button>
            </div>

            {/* Top nav bar */}
            <div className="flex items-center justify-between gap-1 bg-[#1a1a1a] px-3 py-2 absolute top-0 w-full flex-wrap">
                {/* Page count badge */}
                <span className="text-gray-400 text-lg sm:text-xl mr-2 whitespace-nowrap">
                    {loading ? '…' : `${pageNumber} / ${numPages}`}
                </span>

                {/* Zoom controls */}
                <div className="flexCenter gap-1">
                    <NavBtn onClick={zoomOut} disabled={scale <= MIN_SCALE}><MdZoomOut size={20} /></NavBtn>
                    <button
                        onClick={zoomReset}
                        className="min-w-[44px] h-7 px-1.5 rounded text-xs font-semibold text-gray-200 hover:text-white hover:bg-white/20 transition-all"
                    >
                        {Math.round(scale / 1.4 * 100)}%
                    </button>
                    <NavBtn onClick={zoomIn} disabled={scale >= MAX_SCALE}><MdZoomIn size={20} /></NavBtn>
                </div>

                <div className='flexCenter gap-4 flex-wrap'>

                    {/* First */}
                    <NavBtn onClick={goFirst} disabled={pageNumber <= 1}><MdOutlineFirstPage size={20} /></NavBtn>
                    {/* Prev jump */}
                    <NavBtn onClick={() => setPageNumber((p) => Math.max(1, p - 5))} disabled={pageNumber <= 1}><FaAnglesLeft /></NavBtn>

                    {/* Page number buttons */}
                    {getPageButtons().map((p) => (
                        <NavBtn key={p} active={p === pageNumber} onClick={() => setPageNumber(p)}>
                            {p}
                        </NavBtn>
                    ))}

                    {/* Next jump */}
                    <NavBtn onClick={() => setPageNumber((p) => Math.min(numPages, p + 5))} disabled={pageNumber >= numPages}><FaAnglesRight /></NavBtn>
                    {/* Last */}
                    <NavBtn onClick={goLast} disabled={pageNumber >= numPages}><MdOutlineLastPage size={20} /></NavBtn>

                    {/* Close */}
                    <button
                        onClick={onClose}
                        className="w-8 h-8 text-white bg-red-500 hover:text-white transition text-lg font-bold leading-none commonRadius relative z-50"
                    >
                        ✕
                    </button>
                </div>
            </div>
            {/* Center column */}
            <div className="flexColumnCenter" style={{ width: '560px', maxWidth: '90vw' }}>

                {/* Canvas area */}
                <div className="flex-1 w-full overflow-auto bg-white flex items-start justify-center" style={{ maxHeight: 'calc(100vh - 52px)', marginTop: '52px' }}>
                    {loading && (
                        <div className="flexCenter h-full w-full min-h-[600px]">
                            <LoadMoreSpinner />
                        </div>
                    )}
                    {error && (
                        <div className="flexCenter h-full w-full min-h-[600px]">
                            <p className="text-red-500 text-sm px-8 text-center">{error}</p>
                        </div>
                    )}
                    {
                        !loading && !error &&
                        <canvas ref={canvasRef} className="block" />
                    }
                </div>
            </div>

            {/* Right dark panel */}
            <div className="absolute inset-y-0 right-4 flexCenter">
                <button
                    onClick={goNext}
                    disabled={pageNumber >= numPages}
                    className="w-10 h-10 rounded-full bg-white/10 hover:bg-white/25 disabled:opacity-20 disabled:cursor-not-allowed flexCenter text-white text-xl transition"
                >
                    <FaChevronRight />
                </button>
            </div>
        </div>
    );
};

export default PdfViewer;
