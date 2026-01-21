```ts
import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient, QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useReactTable, getCoreRowModel, getSortedRowModel, getFilteredRowModel, flexRender, SortingState } from '@tanstack/react-table';
import { ChevronUp, ChevronDown, ChevronsUpDown, Pencil, Search, ChevronLeft, ChevronRight } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Badge } from '@/components/ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';

// Types
interface CoReportItem {
  id: number;
  coNumber: string;
  customer: string;
  status: string;
  region: string;
  amount: number;
  createdDate: string;
  assignedTo: string;
  priority: string;
  category: string;
}

interface Filters {
  status: string;
  region: string;
  priority: string;
  category: string;
  dateFrom: string;
  dateTo: string;
  customer: string;
}

interface PaginationState {
  page: number;
  pageSize: number;
}

interface ApiResponse {
  data: CoReportItem[];
  totalCount: number;
}

// Mock data store (simulates database)
const mockDataStore: CoReportItem[] = Array.from({ length: 47 }, (_, i) => ({
  id: i + 1,
  coNumber: `CO-${String(1000 + i).padStart(5, '0')}`,
  customer: ['Acme Corp', 'TechStart', 'Global Inc', 'Local LLC', 'Prime Co'][i % 5],
  status: ['Active', 'Pending', 'Closed', 'On Hold'][i % 4],
  region: ['North', 'South', 'East', 'West'][i % 4],
  amount: Math.floor(Math.random() * 50000) + 1000,
  createdDate: new Date(2024, i % 12, (i % 28) + 1).toISOString().split('T')[0],
  assignedTo: ['John D.', 'Sarah M.', 'Mike R.', 'Lisa K.'][i % 4],
  priority: ['High', 'Medium', 'Low'][i % 3],
  category: ['Type A', 'Type B', 'Type C'][i % 3],
}));

// API functions - replace with actual axios/fetch calls
const fetchCoReport = async (filters: Filters, pagination: PaginationState): Promise<ApiResponse> => {
  // Simulates: POST /api/co-report { filters, page, pageSize }
  await new Promise(resolve => setTimeout(resolve, 500));

  let filtered = mockDataStore.filter(item => {
    if (filters.status && filters.status !== 'all' && item.status !== filters.status) return false;
    if (filters.region && filters.region !== 'all' && item.region !== filters.region) return false;
    if (filters.priority && filters.priority !== 'all' && item.priority !== filters.priority) return false;
    if (filters.category && filters.category !== 'all' && item.category !== filters.category) return false;
    if (filters.customer && !item.customer.toLowerCase().includes(filters.customer.toLowerCase())) return false;
    return true;
  });

  const start = (pagination.page - 1) * pagination.pageSize;
  const paginatedData = filtered.slice(start, start + pagination.pageSize);

  return { data: paginatedData, totalCount: filtered.length };
};

const updateCoReportItem = async (item: CoReportItem): Promise<CoReportItem> => {
  // Simulates: PUT /api/co-report/:id
  await new Promise(resolve => setTimeout(resolve, 300));
  const index = mockDataStore.findIndex(i => i.id === item.id);
  if (index !== -1) mockDataStore[index] = item;
  return item;
};

// Filter Card Component
function FilterCard({ filters, setFilters, onApply, isLoading }: {
  filters: Filters;
  setFilters: React.Dispatch<React.SetStateAction<Filters>>;
  onApply: () => void;
  isLoading: boolean;
}) {
  const updateFilter = (key: keyof Filters, value: string) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };

  const clearFilters = () => {
    setFilters({ status: '', region: '', priority: '', category: '', dateFrom: '', dateTo: '', customer: '' });
  };

  return (
    <Card className="w-64 flex-shrink-0 h-fit">
      <CardHeader className="pb-4">
        <div className="flex justify-between items-center">
          <CardTitle className="text-lg">Filters</CardTitle>
          <Button variant="ghost" size="sm" onClick={clearFilters}>Clear all</Button>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <Label>Customer</Label>
          <Input value={filters.customer} onChange={e => updateFilter('customer', e.target.value)} placeholder="Search customer..." />
        </div>
        <div className="space-y-2">
          <Label>Status</Label>
          <Select value={filters.status} onValueChange={v => updateFilter('status', v)}>
            <SelectTrigger><SelectValue placeholder="All" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="Active">Active</SelectItem>
              <SelectItem value="Pending">Pending</SelectItem>
              <SelectItem value="Closed">Closed</SelectItem>
              <SelectItem value="On Hold">On Hold</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>Region</Label>
          <Select value={filters.region} onValueChange={v => updateFilter('region', v)}>
            <SelectTrigger><SelectValue placeholder="All" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="North">North</SelectItem>
              <SelectItem value="South">South</SelectItem>
              <SelectItem value="East">East</SelectItem>
              <SelectItem value="West">West</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>Priority</Label>
          <Select value={filters.priority} onValueChange={v => updateFilter('priority', v)}>
            <SelectTrigger><SelectValue placeholder="All" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="High">High</SelectItem>
              <SelectItem value="Medium">Medium</SelectItem>
              <SelectItem value="Low">Low</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>Category</Label>
          <Select value={filters.category} onValueChange={v => updateFilter('category', v)}>
            <SelectTrigger><SelectValue placeholder="All" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="Type A">Type A</SelectItem>
              <SelectItem value="Type B">Type B</SelectItem>
              <SelectItem value="Type C">Type C</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label>Date From</Label>
          <Input type="date" value={filters.dateFrom} onChange={e => updateFilter('dateFrom', e.target.value)} />
        </div>
        <div className="space-y-2">
          <Label>Date To</Label>
          <Input type="date" value={filters.dateTo} onChange={e => updateFilter('dateTo', e.target.value)} />
        </div>
        <Button className="w-full" onClick={onApply} disabled={isLoading}>
          {isLoading ? 'Loading...' : 'Apply Filters'}
        </Button>
      </CardContent>
    </Card>
  );
}

// Edit Modal Component
function EditModal({ item, open, onClose, onSave, isSaving }: {
  item: CoReportItem | null;
  open: boolean;
  onClose: () => void;
  onSave: (item: CoReportItem) => void;
  isSaving: boolean;
}) {
  const [formData, setFormData] = useState<CoReportItem | null>(item);

  React.useEffect(() => {
    setFormData(item);
  }, [item]);

  if (!formData) return null;

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Edit Record</DialogTitle>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label>CO Number</Label>
            <Input value={formData.coNumber} disabled />
          </div>
          <div className="space-y-2">
            <Label>Customer</Label>
            <Input value={formData.customer} onChange={e => setFormData(prev => prev ? { ...prev, customer: e.target.value } : prev)} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Status</Label>
              <Select value={formData.status} onValueChange={v => setFormData(prev => prev ? { ...prev, status: v } : prev)}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="Active">Active</SelectItem>
                  <SelectItem value="Pending">Pending</SelectItem>
                  <SelectItem value="Closed">Closed</SelectItem>
                  <SelectItem value="On Hold">On Hold</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Priority</Label>
              <Select value={formData.priority} onValueChange={v => setFormData(prev => prev ? { ...prev, priority: v } : prev)}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="High">High</SelectItem>
                  <SelectItem value="Medium">Medium</SelectItem>
                  <SelectItem value="Low">Low</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="space-y-2">
            <Label>Amount</Label>
            <Input type="number" value={formData.amount} onChange={e => setFormData(prev => prev ? { ...prev, amount: Number(e.target.value) } : prev)} />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={isSaving}>Cancel</Button>
          <Button onClick={() => onSave(formData)} disabled={isSaving}>
            {isSaving ? 'Saving...' : 'Save'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// Status Badge
function StatusBadge({ status }: { status: string }) {
  const variant: Record<string, 'default' | 'secondary' | 'destructive' | 'outline'> = {
    Active: 'default',
    Pending: 'secondary',
    Closed: 'outline',
    'On Hold': 'destructive',
  };
  return <Badge variant={variant[status] || 'default'}>{status}</Badge>;
}

// Main Report Component
function CoReportContent() {
  const queryClient = useQueryClient();
  const [filters, setFilters] = useState<Filters>({ status: '', region: '', priority: '', category: '', dateFrom: '', dateTo: '', customer: '' });
  const [appliedFilters, setAppliedFilters] = useState<Filters>(filters);
  const [pagination, setPagination] = useState<PaginationState>({ page: 1, pageSize: 10 });
  const [editItem, setEditItem] = useState<CoReportItem | null>(null);
  const [sorting, setSorting] = useState<SortingState>([]);
  const [globalFilter, setGlobalFilter] = useState('');

  // TanStack Query - fetch data
  const { data: response, isLoading, isFetching } = useQuery({
    queryKey: ['co-report', appliedFilters, pagination],
    queryFn: () => fetchCoReport(appliedFilters, pagination),
  });

  // TanStack Query - mutation for updates
  const updateMutation = useMutation({
    mutationFn: updateCoReportItem,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['co-report'] });
      setEditItem(null);
    },
  });

  const handleApplyFilters = () => {
    setPagination(prev => ({ ...prev, page: 1 }));
    setAppliedFilters(filters);
  };

  const tableData = response?.data ?? [];
  const totalCount = response?.totalCount ?? 0;
  const totalPages = Math.ceil(totalCount / pagination.pageSize);

  const columns = useMemo(() => [
    { accessorKey: 'coNumber', header: 'CO Number' },
    { accessorKey: 'customer', header: 'Customer' },
    { accessorKey: 'status', header: 'Status', cell: ({ row }: any) => <StatusBadge status={row.original.status} /> },
    { accessorKey: 'region', header: 'Region' },
    { accessorKey: 'amount', header: 'Amount', cell: ({ row }: any) => `$${row.original.amount.toLocaleString()}` },
    { accessorKey: 'createdDate', header: 'Created' },
    { accessorKey: 'assignedTo', header: 'Assigned To' },
    { accessorKey: 'priority', header: 'Priority' },
    {
      id: 'actions',
      header: '',
      cell: ({ row }: any) => (
        <Button variant="ghost" size="icon" onClick={() => setEditItem(row.original)}>
          <Pencil className="h-4 w-4" />
        </Button>
      ),
    },
  ], []);

  const table = useReactTable({
    data: tableData,
    columns,
    state: { sorting, globalFilter },
    onSortingChange: setSorting,
    onGlobalFilterChange: setGlobalFilter,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
  });

  return (
    <div className="min-h-screen bg-slate-100 p-6">
      <h1 className="text-2xl font-bold mb-6">CO Report</h1>
      <div className="flex gap-6">
        <FilterCard filters={filters} setFilters={setFilters} onApply={handleApplyFilters} isLoading={isFetching} />

        <Card className="flex-1">
          <CardHeader className="pb-4">
            <div className="flex justify-between items-center">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input value={globalFilter} onChange={e => setGlobalFilter(e.target.value)} placeholder="Filter table..." className="pl-9 w-64" />
              </div>
              <span className="text-sm text-muted-foreground">{totalCount.toLocaleString()} total records</span>
            </div>
          </CardHeader>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  {table.getHeaderGroups().map(hg => (
                    <TableRow key={hg.id}>
                      {hg.headers.map(header => (
                        <TableHead key={header.id} onClick={header.column.getToggleSortingHandler()} className="cursor-pointer hover:bg-muted">
                          <div className="flex items-center gap-1">
                            {flexRender(header.column.columnDef.header, header.getContext())}
                            {header.column.getCanSort() && (
                              header.column.getIsSorted() === 'asc' ? <ChevronUp className="h-4 w-4" /> :
                              header.column.getIsSorted() === 'desc' ? <ChevronDown className="h-4 w-4" /> :
                              <ChevronsUpDown className="h-4 w-4 opacity-30" />
                            )}
                          </div>
                        </TableHead>
                      ))}
                    </TableRow>
                  ))}
                </TableHeader>
                <TableBody>
                  {isLoading ? (
                    <TableRow><TableCell colSpan={columns.length} className="text-center py-8 text-muted-foreground">Loading...</TableCell></TableRow>
                  ) : table.getRowModel().rows.length === 0 ? (
                    <TableRow><TableCell colSpan={columns.length} className="text-center py-8 text-muted-foreground">No results found</TableCell></TableRow>
                  ) : (
                    table.getRowModel().rows.map(row => (
                      <TableRow key={row.id}>
                        {row.getVisibleCells().map(cell => (
                          <TableCell key={cell.id}>{flexRender(cell.column.columnDef.cell, cell.getContext())}</TableCell>
                        ))}
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </div>

            <div className="px-4 py-3 border-t flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">Rows per page:</span>
                <Select value={String(pagination.pageSize)} onValueChange={v => setPagination({ page: 1, pageSize: Number(v) })}>
                  <SelectTrigger className="w-16 h-8"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {[10, 25, 50, 100].map(size => <SelectItem key={size} value={String(size)}>{size}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
              <div className="flex items-center gap-4">
                <span className="text-sm text-muted-foreground">Page {pagination.page} of {totalPages || 1}</span>
                <div className="flex gap-1">
                  <Button variant="outline" size="icon" className="h-8 w-8" onClick={() => setPagination(p => ({ ...p, page: p.page - 1 }))} disabled={pagination.page <= 1 || isFetching}>
                    <ChevronLeft className="h-4 w-4" />
                  </Button>
                  <Button variant="outline" size="icon" className="h-8 w-8" onClick={() => setPagination(p => ({ ...p, page: p.page + 1 }))} disabled={pagination.page >= totalPages || isFetching}>
                    <ChevronRight className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <EditModal
        item={editItem}
        open={!!editItem}
        onClose={() => setEditItem(null)}
        onSave={(item) => updateMutation.mutate(item)}
        isSaving={updateMutation.isPending}
      />
    </div>
  );
}

// Wrap with QueryClientProvider
const queryClient = new QueryClient();

export default function CoReport() {
  return (
    <QueryClientProvider client={queryClient}>
      <CoReportContent />
    </QueryClientProvider>
  );
}
```
