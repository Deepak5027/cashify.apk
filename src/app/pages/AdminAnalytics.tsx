import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../components/ui/card';
import {
  Users, BarChart3, ShieldAlert, TrendingUp, Wallet, Target,
  RefreshCw, Info
} from 'lucide-react';
import { Button } from '../components/ui/button';
import { Badge } from '../components/ui/badge';
import { Progress } from '../components/ui/progress';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Cell
} from 'recharts';
import apiClient from '../../utils/apiClient';
import { toast } from 'sonner';

interface AdminStats {
  totalUsers: number;
  totalTransactions: number;
  totalSpend: number;
  avgSpendPerUser: number;
  flaggedCount: number;
  topCategories: { name: string; total: number }[];
  totalBudgets: number;
  totalGoals: number;
}

const CHART_COLORS = [
  '#6366f1', '#8b5cf6', '#ec4899', '#f59e0b',
  '#10b981', '#3b82f6', '#ef4444', '#14b8a6',
];

/**
 * Admin Analytics — aggregated, anonymized statistics across all users.
 * No PII is returned from the backend; this is purely aggregate data.
 */
export default function AdminAnalytics() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    setLoading(true);
    try {
      const data = await apiClient.get('/api/admin/stats');
      setStats(data);
    } catch (err: any) {
      console.error('Failed to load admin stats:', err);
      toast.error('Failed to load admin statistics');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-[60vh]">
        <div className="text-center space-y-4">
          <BarChart3 className="size-12 animate-pulse mx-auto text-primary" />
          <p className="text-muted-foreground">Loading system statistics...</p>
        </div>
      </div>
    );
  }

  if (!stats) {
    return (
      <div className="flex items-center justify-center h-[60vh]">
        <div className="text-center space-y-4">
          <p className="text-muted-foreground">Failed to load statistics.</p>
          <Button onClick={loadStats}>Retry</Button>
        </div>
      </div>
    );
  }

  const flaggedPct = stats.totalTransactions > 0
    ? ((stats.flaggedCount / stats.totalTransactions) * 100).toFixed(1)
    : '0.0';

  const maxCategory = stats.topCategories[0]?.total || 1;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold flex items-center gap-2">
            <BarChart3 className="size-8 text-primary" />
            System Analytics
          </h1>
          <p className="text-muted-foreground mt-1">
            Aggregated, anonymized metrics across all registered users
          </p>
        </div>
        <Button variant="outline" onClick={loadStats} size="sm">
          <RefreshCw className="size-4 mr-2" />
          Refresh
        </Button>
      </div>

      {/* Privacy notice */}
      <Card className="border-blue-200 bg-blue-50">
        <CardContent className="pt-4 pb-4">
          <div className="flex items-start gap-3">
            <Info className="size-5 text-blue-600 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-blue-800">
              This view shows <strong>anonymized aggregate statistics only</strong> — no names, emails, or
              individual transaction details are visible here. Data is read from the database in summary form.
            </p>
          </div>
        </CardContent>
      </Card>

      {/* KPI cards */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Users</CardTitle>
            <Users className="size-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{stats.totalUsers.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">Registered accounts</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Transactions</CardTitle>
            <TrendingUp className="size-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{stats.totalTransactions.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground mt-1">Across all users</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Spend</CardTitle>
            <Wallet className="size-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">
              &#8377;{stats.totalSpend.toLocaleString('en-IN')}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Avg &#8377;{stats.avgSpendPerUser.toLocaleString('en-IN')} / user
            </p>
          </CardContent>
        </Card>

        <Card className={stats.flaggedCount > 0 ? 'border-red-200' : ''}>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Flagged Transactions</CardTitle>
            <ShieldAlert className={`size-4 ${stats.flaggedCount > 0 ? 'text-red-500' : 'text-muted-foreground'}`} />
          </CardHeader>
          <CardContent>
            <div className={`text-3xl font-bold ${stats.flaggedCount > 0 ? 'text-red-600' : ''}`}>
              {stats.flaggedCount}
            </div>
            <div className="flex items-center gap-2 mt-2">
              <Progress
                value={parseFloat(flaggedPct)}
                className="h-1.5 flex-1"
              />
              <span className="text-xs text-muted-foreground">{flaggedPct}%</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Budgets</CardTitle>
            <BarChart3 className="size-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{stats.totalBudgets}</div>
            <p className="text-xs text-muted-foreground mt-1">Budget categories set</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Savings Goals</CardTitle>
            <Target className="size-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{stats.totalGoals}</div>
            <p className="text-xs text-muted-foreground mt-1">Goals created</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Fraud Rate</CardTitle>
            <ShieldAlert className="size-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{flaggedPct}%</div>
            <p className="text-xs text-muted-foreground mt-1">Of all transactions</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Tx / User</CardTitle>
            <TrendingUp className="size-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">
              {stats.totalUsers > 0
                ? (stats.totalTransactions / stats.totalUsers).toFixed(1)
                : '0'}
            </div>
            <p className="text-xs text-muted-foreground mt-1">Transactions per user</p>
          </CardContent>
        </Card>
      </div>

      {/* Top Categories Chart */}
      {stats.topCategories.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Top Spending Categories</CardTitle>
            <CardDescription>
              Aggregate spend across all users by category (no user data shown)
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart
                data={stats.topCategories}
                layout="vertical"
                margin={{ left: 20, right: 30 }}
              >
                <CartesianGrid strokeDasharray="3 3" horizontal={false} />
                <XAxis
                  type="number"
                  tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}k`}
                />
                <YAxis type="category" dataKey="name" width={90} />
                <Tooltip
                  formatter={(value: number) =>
                    [`₹${value.toLocaleString('en-IN')}`, 'Total Spend']
                  }
                />
                <Bar dataKey="total" radius={[0, 4, 4, 0]}>
                  {stats.topCategories.map((_, idx) => (
                    <Cell key={idx} fill={CHART_COLORS[idx % CHART_COLORS.length]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      )}

      {/* Category breakdown list */}
      {stats.topCategories.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Category Breakdown</CardTitle>
            <CardDescription>Ranked by aggregate spend, all users combined</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {stats.topCategories.map((cat, idx) => {
              const pct = Math.round((cat.total / maxCategory) * 100);
              return (
                <div key={cat.name} className="space-y-1">
                  <div className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <span
                        className="w-3 h-3 rounded-full inline-block"
                        style={{ background: CHART_COLORS[idx % CHART_COLORS.length] }}
                      />
                      <span className="font-medium capitalize">{cat.name}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="secondary">
                        &#8377;{cat.total.toLocaleString('en-IN')}
                      </Badge>
                    </div>
                  </div>
                  <Progress value={pct} className="h-2" />
                </div>
              );
            })}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
