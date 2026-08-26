import { Card } from "../components/ui/card";
import { Button } from "../components/ui/button";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "../components/ui/tabs";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../components/ui/select";
import {
  categories,
} from "../data/mockData";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  Legend,
  Area,
  AreaChart,
} from "recharts";
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  ShoppingBag,
  Download,
  BarChart3 as BarChartIcon,
} from "lucide-react";
import { useState, useEffect } from "react";
import { transactionsAPI } from "../../services/api";
import { toast } from "sonner";
import jsPDF from "jspdf";

const COLORS = [
  "#3b82f6",
  "#ef4444",
  "#10b981",
  "#f59e0b",
  "#8b5cf6",
  "#ec4899",
  "#06b6d4",
  "#84cc16",
  "#6366f1",
];

export default function Analytics() {
  const [timeRange, setTimeRange] = useState("month");
  const [transactions, setTransactions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadTransactions();
  }, []);

  const loadTransactions = async () => {
    try {
      const response = await transactionsAPI.getAll();
      setTransactions(response.transactions || []);
    } catch (error) {
      console.error("Failed to load transactions:", error);
      toast.error("Failed to load analytics data");
    } finally {
      setLoading(false);
    }
  };

  const totalSpent = transactions
    .filter((t) => t.type === "expense")
    .reduce((sum, t) => sum + t.amount, 0);

  const totalIncome = transactions
    .filter((t) => t.type === "income")
    .reduce((sum, t) => sum + t.amount, 0);

  const avgTransaction =
    totalSpent /
    (transactions.filter((t) => t.type === "expense").length || 1);

  // Group by merchant for expenses
  const topMerchants = transactions
    .filter((t) => t.type === "expense")
    .reduce((acc: any[], t) => {
      const name = t.merchant || t.description || "Unknown";
      const existing = acc.find((m) => m.merchant === name);
      if (existing) {
        existing.total += t.amount;
        existing.count += 1;
      } else {
        acc.push({
          merchant: name,
          total: t.amount,
          count: 1,
        });
      }
      return acc;
    }, [])
    .sort((a, b) => b.total - a.total)
    .slice(0, 5);

  // Calculate category spending
  const categorySpending: { category: string; value: number }[] = Object.entries(
    transactions
      .filter((t) => t.type === "expense")
      .reduce((acc: Record<string, number>, t: any) => {
        const cat = t.category || "Other";
        acc[cat] = (acc[cat] || 0) + (Number(t.amount) || 0);
        return acc;
      }, {})
  ).map(([category, value]) => ({ category, value: Number(value) || 0 }));

  // Calculate monthly data for the current year
  const monthsList = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  const currentYear = new Date().getFullYear();
  const monthlyData = monthsList.map((m, idx) => {
    const spent = transactions
      .filter((t) => {
        const d = new Date(t.date);
        return d.getFullYear() === currentYear && d.getMonth() === idx && t.type === "expense";
      })
      .reduce((sum, t) => sum + t.amount, 0);
    const income = transactions
      .filter((t) => {
        const d = new Date(t.date);
        return d.getFullYear() === currentYear && d.getMonth() === idx && t.type === "income";
      })
      .reduce((sum, t) => sum + t.amount, 0);
    return { month: m, spent, income };
  });

  // For trends logic: find highest/lowest spend months
  const activeMonths = monthlyData.filter((m) => m.spent > 0);
  const highestMonthObj = activeMonths.length > 0
    ? [...activeMonths].sort((a, b) => b.spent - a.spent)[0]
    : { month: "N/A", spent: 0 };
  const lowestMonthObj = activeMonths.length > 0
    ? [...activeMonths].sort((a, b) => a.spent - b.spent)[0]
    : { month: "N/A", spent: 0 };

  const activeMonthsCount = activeMonths.length || 1;
  const avgMonthlySpend = totalSpent / activeMonthsCount;

  // AI predictions
  const nextMonthForecast = Math.round(avgMonthlySpend * 1.04) || 25000;
  const topCategories = [...categorySpending].sort((a, b) => b.value - a.value).slice(0, 3);

  const generatePDFReport = () => {
    toast.info("Generating PDF report...");

    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.getWidth();

    // Title
    doc.setFontSize(24);
    doc.setTextColor(59, 130, 246);
    doc.text("FinanceAI Monthly Report", pageWidth / 2, 20, {
      align: "center",
    });

    // Date
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(
      `Generated on: ${new Date().toLocaleDateString()}`,
      pageWidth / 2,
      28,
      { align: "center" },
    );

    // Financial Summary
    doc.setFontSize(16);
    doc.setTextColor(0);
    doc.text("Financial Summary", 20, 45);

    doc.setFontSize(11);
    doc.setTextColor(60);
    const summaryY = 55;
    doc.text(
      `Total Income: Rs. ${totalIncome.toLocaleString()}`,
      20,
      summaryY,
    );
    doc.text(
      `Total Expenses: Rs. ${totalSpent.toLocaleString()}`,
      20,
      summaryY + 7,
    );
    doc.text(
      `Net Balance: Rs. ${(totalIncome - totalSpent).toLocaleString()}`,
      20,
      summaryY + 14,
    );
    doc.text(
      `Savings Rate: ${totalIncome > 0 ? (((totalIncome - totalSpent) / totalIncome) * 100).toFixed(1) : 0}%`,
      20,
      summaryY + 21,
    );
    doc.text(
      `Average Transaction: Rs. ${avgTransaction.toLocaleString(undefined, { maximumFractionDigits: 2 })}`,
      20,
      summaryY + 28,
    );
    doc.text(
      `Total Transactions: ${transactions.length}`,
      20,
      summaryY + 35,
    );

    // Top Merchants
    doc.setFontSize(16);
    doc.setTextColor(0);
    doc.text("Top Merchants", 20, 110);

    doc.setFontSize(10);
    doc.setTextColor(60);
    let merchantY = 120;
    topMerchants.forEach((merchant, index) => {
      doc.text(
        `${index + 1}. ${merchant.merchant} - Rs. ${merchant.total.toLocaleString()} (${merchant.count} transactions)`,
        20,
        merchantY,
      );
      merchantY += 7;
    });

    // Category Breakdown
    doc.setFontSize(16);
    doc.setTextColor(0);
    doc.text("Spending by Category", 20, merchantY + 15);

    doc.setFontSize(10);
    doc.setTextColor(60);
    let categoryY = merchantY + 25;
    categorySpending
      .sort((a, b) => b.value - a.value)
      .forEach((cat) => {
        const percentage = totalSpent > 0 ? ((cat.value / totalSpent) * 100).toFixed(1) : "0";
        doc.text(
          `${cat.category}: Rs. ${cat.value.toLocaleString()} (${percentage}%)`,
          20,
          categoryY,
        );
        categoryY += 7;
      });

    // Footer
    doc.setFontSize(8);
    doc.setTextColor(150);
    doc.text(
      "Powered by FinanceAI - Your AI-Powered Personal Finance Assistant",
      pageWidth / 2,
      280,
      { align: "center" },
    );

    // Save PDF
    doc.save(
      `FinanceAI_Report_${new Date().toISOString().split("T")[0]}.pdf`,
    );
    toast.success("PDF report downloaded!");
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Loading analytics...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-7xl">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-bold">
            Analytics & Reports
          </h1>
          <p className="text-gray-600 mt-1">
            Deep insights into your spending patterns
          </p>
        </div>
        <div className="flex gap-3">
          <Button onClick={generatePDFReport} variant="outline">
            <Download className="w-4 h-4 mr-2" />
            Export PDF
          </Button>
          <Select
            value={timeRange}
            onValueChange={setTimeRange}
          >
            <SelectTrigger className="w-40">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="week">This Week</SelectItem>
              <SelectItem value="month">This Month</SelectItem>
              <SelectItem value="year">This Year</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">
                Total Spent
              </p>
              <p className="text-2xl font-bold mt-1">
                ₹{totalSpent.toLocaleString()}
              </p>
              <p className="text-sm text-red-600 mt-1 flex items-center">
                <TrendingUp className="w-4 h-4 mr-1" />
                Active expenses
              </p>
            </div>
            <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
              <DollarSign className="w-6 h-6 text-red-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">
                Total Income
              </p>
              <p className="text-2xl font-bold mt-1">
                ₹{totalIncome.toLocaleString()}
              </p>
              <p className="text-sm text-green-600 mt-1 flex items-center">
                <TrendingUp className="w-4 h-4 mr-1" />
                Active earnings
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">
                Avg Transaction
              </p>
              <p className="text-2xl font-bold mt-1">
                ₹{avgTransaction.toLocaleString(undefined, { maximumFractionDigits: 2 })}
              </p>
              <p className="text-sm text-gray-500 mt-1">
                Per transaction
              </p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
              <ShoppingBag className="w-6 h-6 text-blue-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">
                Transactions
              </p>
              <p className="text-2xl font-bold mt-1">
                {transactions.length}
              </p>
              <p className="text-sm text-gray-500 mt-1">
                Database entries
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
              <BarChartIcon className="w-6 h-6 text-purple-600" />
            </div>
          </div>
        </Card>
      </div>

      {/* Charts Tabs */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="categories">
            Categories
          </TabsTrigger>
          <TabsTrigger value="trends">Trends</TabsTrigger>
          <TabsTrigger value="merchants">Merchants</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          <div className="grid lg:grid-cols-2 gap-4">
            {/* Monthly Spending Trend */}
            <Card className="p-6">
              <h3 className="font-bold text-lg mb-4">
                Monthly Spending Trend
              </h3>
              <ResponsiveContainer width="100%" height={300} key="analytics-monthly-area">
                <AreaChart data={monthlyData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis />
                  <Tooltip />
                  <Area
                    type="monotone"
                    dataKey="spent"
                    stroke="#3b82f6"
                    fill="#3b82f6"
                    fillOpacity={0.2}
                    name="Spent"
                    id="area-spent"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </Card>

            {/* Category Distribution */}
            <Card className="p-6">
              <h3 className="font-bold text-lg mb-4">
                Spending Distribution
              </h3>
              <ResponsiveContainer width="100%" height={300} key="analytics-pie-overview">
                <PieChart>
                  <Pie
                    data={categorySpending.map(c => ({ ...c, name: c.category }))}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percent }) =>
                      `${name} ${(percent * 100).toFixed(0)}%`
                    }
                    outerRadius={100}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {categorySpending.map((_, index) => (
                      <Cell
                        key={`overview-cell-${index}`}
                        fill={COLORS[index % COLORS.length]}
                      />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="categories" className="space-y-4">
          <Card className="p-6">
            <h3 className="font-bold text-lg mb-4">
              Spending by Category
            </h3>
            <ResponsiveContainer width="100%" height={400} key="analytics-category-bar">
              <BarChart
                data={categorySpending}
                layout="vertical"
              >
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis type="number" />
                <YAxis
                  dataKey="category"
                  type="category"
                  width={100}
                />
                <Tooltip />
                <Bar dataKey="value" fill="#3b82f6" />
              </BarChart>
            </ResponsiveContainer>
          </Card>

          {/* Category Details */}
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {categorySpending.map((cat, idx) => {
              const category = categories.find(
                (c) => c.name === cat.category,
              );
              const percentage = (cat.value / totalSpent) * 100;
              return (
                <Card key={cat.category} className="p-6">
                  <div className="flex items-start justify-between mb-3">
                    <div
                      className="w-10 h-10 rounded-full flex items-center justify-center"
                      style={{
                        backgroundColor: `${COLORS[idx]}20`,
                      }}
                    >
                      <div
                        className="w-5 h-5 rounded-full"
                        style={{ backgroundColor: COLORS[idx] }}
                      />
                    </div>
                    <div className="text-right">
                      <p className="text-2xl font-bold">
                        ₹{cat.value.toLocaleString()}
                      </p>
                      <p className="text-sm text-gray-600">
                        {percentage.toFixed(1)}%
                      </p>
                    </div>
                  </div>
                  <p className="font-medium">{cat.category}</p>
                  <p className="text-sm text-gray-600 mt-1">
                    {
                      transactions.filter(
                        (t) => t.category === category?.id,
                      ).length
                    }{" "}
                    transactions
                  </p>
                </Card>
              );
            })}
          </div>
        </TabsContent>

        <TabsContent value="trends" className="space-y-4">
          <Card className="p-6">
            <h3 className="font-bold text-lg mb-4">
              6-Month Spending History
            </h3>
            <ResponsiveContainer width="100%" height={400} key="analytics-trends-line">
              <LineChart data={monthlyData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="spent"
                  stroke="#3b82f6"
                  strokeWidth={3}
                  name="Spending"
                />
              </LineChart>
            </ResponsiveContainer>
          </Card>

          <div className="grid lg:grid-cols-2 gap-4">
            <Card className="p-6">
              <h3 className="font-bold mb-4">
                Spending Insights
              </h3>
              <div className="space-y-4">
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <div className="flex items-start gap-3">
                    <TrendingUp className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
                    <div className="text-sm">
                      <p className="font-medium text-blue-900">
                        Highest Month
                      </p>
                      <p className="text-blue-700">
                        {highestMonthObj.month} with ₹{highestMonthObj.spent.toLocaleString()} in expenses
                      </p>
                    </div>
                  </div>
                </div>
                <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                  <div className="flex items-start gap-3">
                    <TrendingDown className="w-5 h-5 text-green-600 flex-shrink-0 mt-0.5" />
                    <div className="text-sm">
                      <p className="font-medium text-green-900">
                        Lowest Month
                      </p>
                      <p className="text-green-700">
                        {lowestMonthObj.month} with ₹{lowestMonthObj.spent.toLocaleString()} in expenses
                      </p>
                    </div>
                  </div>
                </div>
                <div className="p-4 bg-purple-50 border border-purple-200 rounded-lg">
                  <div className="text-sm">
                    <p className="font-medium text-purple-900">
                      Average Monthly Spend
                    </p>
                    <p className="text-2xl font-bold text-purple-600 mt-1">
                      ₹{avgMonthlySpend.toLocaleString(undefined, { maximumFractionDigits: 0 })}
                    </p>
                  </div>
                </div>
              </div>
            </Card>

            <Card className="p-6">
              <h3 className="font-bold mb-4">AI Predictions</h3>
              <div className="space-y-4">
                <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg">
                  <p className="font-medium text-orange-900 mb-2">
                    Next Month Forecast
                  </p>
                  <p className="text-3xl font-bold text-orange-600">
                    ₹{nextMonthForecast.toLocaleString()}
                  </p>
                  <p className="text-sm text-orange-700 mt-1">
                    Based on current year's active monthly spend trend
                  </p>
                </div>
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <p className="font-medium text-blue-900 mb-2">
                    Categories to Watch
                  </p>
                  <ul className="text-sm text-blue-700 space-y-1">
                    {topCategories.length > 0 ? (
                      topCategories.map((c, idx) => (
                        <li key={idx}>• {c.category}: ₹{c.value.toLocaleString()} spent</li>
                      ))
                    ) : (
                      <li>No expense entries recorded yet to forecast.</li>
                    )}
                  </ul>
                </div>
              </div>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="merchants" className="space-y-4">
          <Card className="p-6">
            <h3 className="font-bold text-lg mb-4">
              Top Merchants by Spending
            </h3>
            <div className="space-y-4">
              {topMerchants.length === 0 ? (
                <div className="text-center py-6 text-sm text-gray-500">No merchant expenses recorded</div>
              ) : (
                topMerchants.map((merchant, idx) => (
                  <div
                    key={merchant.merchant}
                    className="flex items-center gap-4"
                  >
                    <div className="flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 text-blue-600 font-bold text-sm">
                      {idx + 1}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between mb-1">
                        <p className="font-medium">
                          {merchant.merchant}
                        </p>
                        <p className="font-bold">
                          ₹{merchant.total.toLocaleString()}
                        </p>
                      </div>
                      <div className="flex items-center justify-between text-sm text-gray-600">
                        <p>{merchant.count} transactions</p>
                        <p>
                          ₹{(merchant.total / merchant.count).toLocaleString(undefined, { maximumFractionDigits: 2 })} avg
                        </p>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}