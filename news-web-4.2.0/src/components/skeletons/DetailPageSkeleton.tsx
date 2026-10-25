import { Skeleton } from "../ui/skeleton"

const DetailPageSkeleton = () => {
  return (
    <section className='container commonMT'>
      <div className='grid grid-cols-12 gap-y-10 lg:gap-8'>
        <div className='col-span-12 lg:col-span-8 flex flex-col gap-8'>
          <div className='flex flex-col gap-3'>
            <Skeleton height={30} width={120} />
            <Skeleton height={50} />
          </div>
          <Skeleton height={40} />
          <Skeleton height={400} />
          <Skeleton height={90} />
          <div className='flex flex-col gap-3'>
            <Skeleton height={20} />
            <Skeleton height={20} />
            <Skeleton height={20} />
            <Skeleton height={20} width={'70%'} />
          </div>
        </div>

        <div className='col-span-12 lg:col-span-4 flex flex-col gap-6'>
          <Skeleton height={300} />
          <Skeleton height={200} />
        </div>
      </div>
    </section>
  )
}

export default DetailPageSkeleton
