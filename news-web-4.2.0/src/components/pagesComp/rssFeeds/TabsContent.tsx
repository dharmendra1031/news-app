'use client'
import { useEffect } from 'react'
import { useTranslation } from '@/hooks/useTranslation'

interface TabsContentProps<T> {
    data?: T[]
    selectedIds: string
    setSelectedIds: (ids: string) => void
    selectedItems: Record<string, boolean>
    setSelectedItems: React.Dispatch<React.SetStateAction<Record<string, boolean>>>
    labelKey: keyof T
    idKey: keyof T
    showLoadMore?: boolean
    onLoadMore?: () => void
}

const TabsContent = <T,>({
    data = [],
    setSelectedIds,
    selectedItems,
    setSelectedItems,
    labelKey,
    idKey,
    showLoadMore = false,
    onLoadMore,
}: TabsContentProps<T>) => {

    const { t } = useTranslation()

    // Update the comma-separated string whenever selections change
    useEffect(() => {
        const selectedNames = Object.keys(selectedItems)
            .filter(item => selectedItems[item])
            .join(", ");
        setSelectedIds(selectedNames);
    }, [selectedItems, setSelectedIds]);

    // Split data into two halves
    const halfLength = Math.ceil(data.length / 2);
    const leftItems = data.slice(0, halfLength);
    const rightItems = data.slice(halfLength);

    // Handle selection/deselection
    const handleToggle = (item: T) => {
        const id = String(item[idKey])
        setSelectedItems(prev => ({
            ...prev,
            [id]: !prev[id]
        }));
    };

    // Render a single item
    const renderItem = (item: T) => {
        const id = String(item[idKey])
        return (
            <div
                key={id}
                className="flex items-center justify-between py-2 cursor-pointer"
                onClick={() => handleToggle(item)}
            >
                <span className="text-gray-800 font-medium break-all first-letter:capitalize">{String(item[labelKey])}</span>
                <div className={`h-6 w-6 border border-gray-300 rounded flex items-center justify-center ${selectedItems[id] ? 'primaryBg' : 'bg-white'}`}>
                    {selectedItems[id] && (
                        <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4 text-white" viewBox="0 0 20 20" fill="currentColor">
                            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                        </svg>
                    )}
                </div>
            </div>
        )
    };
    return (
        data?.length > 0 ?
            <div className="bg-white rounded-[8px] border borderColor p-2 sm:p-4 h-[300px] overflow-y-auto sm:h-max customScrollBar">
                <div className="flex">
                    {/* Left Column */}
                    <div className="flex-1 ltr:border-r rtl:border-l borderColor rtl:pl-4 ltr:pr-4">
                        {leftItems.map(item => renderItem(item))}
                    </div>

                    {/* Right Column */}
                    <div className="flex-1 ltr:pl-4 rtl:pr-4">
                        {rightItems.map(item => renderItem(item))}
                    </div>
                </div>

                {
                    showLoadMore && onLoadMore &&
                    <div className='flexCenter gap-2 mt-8'>
                        <button className='commonBtn !text-sm' onClick={onLoadMore}>{t('loadMore')}</button>
                    </div>
                }
            </div>
            :
            <div className='text-[#1B2D51] dark:text-white flexCenter h-[250px] overflow-hidden font-[600] text-lg'>
                {t('nodatafound')}
            </div>
    );
};

export default TabsContent;
