import { cn } from '@/lib/utils'

interface TableProps {
  headers: string[]
  children: React.ReactNode
  className?: string
}

export function Table({ headers, children, className }: TableProps) {
  return (
    <div className={cn('overflow-x-auto rounded-2xl border border-border/80 bg-surface', className)}>
      <table className="min-w-full divide-y divide-border/80">
        <thead className="bg-sidebar/70">
          <tr>
            {headers.map((h) => (
              <th key={h} className="px-4 py-3 text-left text-[11px] font-semibold text-fg-muted uppercase tracking-[0.14em]">
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-border/70 bg-surface">{children}</tbody>
      </table>
    </div>
  )
}

export function TableRow({ children, className }: { children: React.ReactNode; className?: string }) {
  return <tr className={cn('hover:bg-accent-surface/25 transition-colors duration-100', className)}>{children}</tr>
}

export function TableCell({ children, className }: { children: React.ReactNode; className?: string }) {
  return <td className={cn('px-4 py-3.5 text-sm text-fg align-middle', className)}>{children}</td>
}
