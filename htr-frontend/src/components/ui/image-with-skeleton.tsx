import { useState } from 'react'
import { cn } from '@/lib/utils'
import { Skeleton } from '@/components/ui/feedback'

interface ImageWithSkeletonProps {
  src: string
  alt: string
  className?: string
  objectFit?: 'cover' | 'contain'
}

export function ImageWithSkeleton({ src, alt, className, objectFit = 'cover' }: ImageWithSkeletonProps) {
  const [loaded, setLoaded] = useState(false)
  const [trackedSrc, setTrackedSrc] = useState(src)

  // A new src means a new image to wait on — reset during render (not an effect)
  // so the skeleton reappears in the same commit the src changes, per
  // https://react.dev/learn/you-might-not-need-an-effect#adjusting-some-state-when-a-prop-changes.
  if (src !== trackedSrc) {
    setTrackedSrc(src)
    setLoaded(false)
  }

  return (
    <div className={cn('relative overflow-hidden', objectFit === 'contain' && 'bg-sidebar/50', className)}>
      {!loaded && (
        <div data-testid="image-skeleton" className="absolute inset-0">
          <Skeleton className="h-full w-full rounded-none" />
        </div>
      )}
      <img
        src={src}
        alt={alt}
        onLoad={() => setLoaded(true)}
        onError={() => setLoaded(true)}
        className={cn(
          'absolute inset-0 h-full w-full opacity-0 transition-opacity duration-300',
          objectFit === 'contain' ? 'object-contain' : 'object-cover',
          loaded && 'opacity-100'
        )}
      />
    </div>
  )
}
