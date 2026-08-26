import { useState, useEffect } from "react";
import { Card } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Badge } from "../components/ui/badge";
import { Progress } from "../components/ui/progress";
import {
  Brain,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  Target,
  Lightbulb,
  Zap,
  Calendar,
  DollarSign,
  Award,
} from "lucide-react";
import { aiAPI } from "../../services/api";
import { toast } from "sonner";

export default function SmartInsights() {
  const [insights, setInsights] = useState<any[]>([]);
  const [analytics, setAnalytics] = useState<any>(null);
  const [predictions, setPredictions] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadInsights();
  }, []);

  const loadInsights = async () => {
    try {
      const [insightsRes, analyticsRes, predictionsRes] = await Promise.all([
        aiAPI.getInsights(),
        aiAPI.getAnalytics(),
        aiAPI.predictSpending(),
      ]);

      setInsights(insightsRes.insights || []);
      setAnalytics(analyticsRes.analytics || {});
      setPredictions(predictionsRes.predictions || {});
    } catch (error: any) {
      console.error('Failed to load insights:', error);
      toast.error('Failed to load AI insights');
    } finally {
      setLoading(false);
    }
  };

  const mockInsights = [
    {
      type: "warning",
      title: "Unusual Spending Pattern Detected",
      description:
        "Your shopping expenses increased by 355% this month. AI detected 3 large purchases that are unusual for your profile.",
      action: "Review Transactions",
      priority: "high",
      icon: AlertTriangle,
    },
    {
      type: "success",
      title: "Savings Opportunity Identified",
      description:
        "You could save $85/month by switching to annual subscriptions instead of monthly. Netflix, Spotify, and Adobe detected.",
      action: "See Details",
      priority: "medium",
      icon: Target,
    },
    {
      type: "info",
      title: "Predictive Budget Alert",
      description:
        "Based on your current spending pattern, you'll exceed your food delivery budget by $120 in the next 2 weeks.",
      action: "Adjust Budget",
      priority: "medium",
      icon: TrendingUp,
    },
    {
      type: "success",
      title: "Smart Bill Reminder",
      description:
        "Your electricity bill of ~$120 is due in 3 days. AI predicted the amount based on seasonal patterns.",
      action: "Mark Paid",
      priority: "high",
      icon: Calendar,
    },
  ];

  const recommendations = [
    {
      title: "Optimize Subscription Stack",
      savings: 156,
      effort: "low",
      impact: "high",
      description: "Cancel 2 duplicate streaming services and switch to annual billing",
    },
    {
      title: "Reduce Food Delivery",
      savings: 280,
      effort: "medium",
      impact: "high",
      description: "Limit deliveries to 2x per week based on your historical data",
    },
    {
      title: "Switch to Generic Brands",
      savings: 95,
      effort: "low",
      impact: "medium",
      description: "AI identified 8 items at Whole Foods with cheaper alternatives",
    },
    {
      title: "Bundle Insurance",
      savings: 320,
      effort: "high",
      impact: "high",
      description: "Potential savings by bundling auto and home insurance",
    },
  ];

  const behaviorAnalysis = [
    { day: "Monday", spending: 45, prediction: 42 },
    { day: "Tuesday", spending: 78, prediction: 65 },
    { day: "Wednesday", spending: 52, prediction: 55 },
    { day: "Thursday", spending: 125, prediction: 70 },
    { day: "Friday", spending: 180, prediction: 150 },
    { day: "Saturday", spending: 210, prediction: 180 },
    { day: "Sunday", spending: 95, prediction: 85 },
  ];

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Loading AI insights...</p>
        </div>
      </div>
    );
  }

  const healthScore = analytics?.financial_health_score || 78;
  const scoreLabel = healthScore >= 80 ? 'Excellent' : healthScore >= 60 ? 'Good' : 'Needs Work';

  // Map insight types to icons
  const getInsightIcon = (type: string) => {
    switch (type) {
      case 'fraud_alert':
        return AlertTriangle;
      case 'budget_alert':
        return Target;
      case 'spending_pattern':
      case 'spending_trend':
        return TrendingUp;
      case 'savings_opportunity':
        return DollarSign;
      default:
        return Lightbulb;
    }
  };

  // Map priority to variant
  const getInsightVariant = (priority: string) => {
    if (priority === 'critical') return 'warning';
    if (priority === 'high') return 'warning';
    if (priority === 'medium') return 'info';
    return 'success';
  };

  return (
    <div className="space-y-6 max-w-7xl">
      {/* Header */}
      <div>
        <h1 className="text-2xl lg:text-3xl font-bold">Smart Insights</h1>
        <p className="text-gray-600 mt-1">AI-powered recommendations and predictions</p>
      </div>

      {/* AI Score */}
      <Card className="p-6 bg-gradient-to-br from-purple-500 to-blue-500 text-white">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm">
              <Brain className="w-8 h-8" />
            </div>
            <div>
              <h3 className="text-2xl font-bold">Financial Health Score</h3>
              <p className="text-white/80">AI-calculated based on your financial data</p>
            </div>
          </div>
          <div className="text-right">
            <div className="text-5xl font-bold">{healthScore}</div>
            <div className="text-white/80">{scoreLabel}</div>
          </div>
        </div>
        <div className="mt-6 grid grid-cols-4 gap-4">
          <div>
            <div className="text-white/80 text-sm">Income</div>
            <div className="text-xl font-bold">₹{analytics?.total_income?.toFixed(0) || 0}</div>
          </div>
          <div>
            <div className="text-white/80 text-sm">Expenses</div>
            <div className="text-xl font-bold">₹{analytics?.total_expense?.toFixed(0) || 0}</div>
          </div>
          <div>
            <div className="text-white/80 text-sm">Savings</div>
            <div className="text-xl font-bold">₹{analytics?.net_savings?.toFixed(0) || 0}</div>
          </div>
          <div>
            <div className="text-white/80 text-sm">Savings Rate</div>
            <div className="text-xl font-bold">{analytics?.savings_rate?.toFixed(0) || 0}%</div>
          </div>
        </div>
      </Card>

      {/* Priority Insights */}
      <div className="space-y-4">
        <h2 className="text-xl font-bold">Priority Insights</h2>
        {insights.length === 0 ? (
          <Card className="p-8 text-center text-gray-500">
            <Lightbulb className="w-12 h-12 mx-auto mb-4 text-gray-400" />
            <p>No insights yet. Add some transactions to get AI-powered recommendations!</p>
          </Card>
        ) : (
          <div className="grid gap-4">
            {insights.map((insight, idx) => {
              const Icon = getInsightIcon(insight.type);
              const variant = getInsightVariant(insight.priority);
              return (
                <Card
                  key={idx}
                  className={`p-6 ${
                    variant === "warning"
                      ? "border-orange-300 bg-orange-50"
                      : variant === "success"
                      ? "border-green-300 bg-green-50"
                      : "border-blue-300 bg-blue-50"
                  }`}
                >
                  <div className="flex items-start gap-4">
                    <div
                      className={`w-12 h-12 rounded-full flex items-center justify-center ${
                        variant === "warning"
                          ? "bg-orange-200"
                          : variant === "success"
                          ? "bg-green-200"
                          : "bg-blue-200"
                      }`}
                    >
                      <Icon
                        className={`w-6 h-6 ${
                          variant === "warning"
                            ? "text-orange-700"
                            : variant === "success"
                            ? "text-green-700"
                            : "text-blue-700"
                        }`}
                      />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <h3 className="font-bold text-lg">{insight.title}</h3>
                        <Badge variant={insight.priority === "critical" || insight.priority === "high" ? "destructive" : "default"}>
                          {insight.priority}
                        </Badge>
                      </div>
                      <p className="text-gray-700 mb-3">{insight.description}</p>
                    </div>
                  </div>
                </Card>
              );
            })}
          </div>
        )}
      </div>

      {/* Savings Recommendations */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold">AI Recommendations</h2>
          <div className="text-sm text-gray-600">
            Potential savings: <span className="text-green-600 font-bold text-lg">₹851/month</span>
          </div>
        </div>
        <div className="grid sm:grid-cols-2 gap-4">
          {recommendations.map((rec, idx) => (
            <Card key={idx} className="p-6">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                    <DollarSign className="w-5 h-5 text-green-600" />
                  </div>
                  <div>
                    <h3 className="font-bold">{rec.title}</h3>
                    <p className="text-2xl font-bold text-green-600">₹{rec.savings}/mo</p>
                  </div>
                </div>
                <Badge
                  variant={
                    rec.impact === "high" ? "default" : rec.impact === "medium" ? "secondary" : "outline"
                  }
                >
                  {rec.impact} impact
                </Badge>
              </div>
              <p className="text-sm text-gray-600 mb-3">{rec.description}</p>
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Zap className="w-4 h-4" />
                <span className="capitalize">{rec.effort} effort required</span>
              </div>
            </Card>
          ))}
        </div>
      </div>

      {/* Spending Pattern Analysis */}
      <Card className="p-6">
        <h3 className="font-bold text-lg mb-4">Weekly Spending Pattern Analysis</h3>
        <div className="space-y-3">
          {behaviorAnalysis.map((day, idx) => {
            const variance = ((day.spending - day.prediction) / day.prediction) * 100;
            return (
              <div key={idx}>
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium">{day.day}</span>
                  <div className="flex items-center gap-4">
                    <span className="text-sm text-gray-600">
                      Predicted: ₹{day.prediction}
                    </span>
                    <span
                      className={`font-bold ${
                        variance > 10 ? "text-red-600" : variance < -10 ? "text-green-600" : "text-gray-900"
                      }`}
                    >
                      Actual: ₹{day.spending}
                    </span>
                    {Math.abs(variance) > 10 && (
                      <Badge variant={variance > 0 ? "destructive" : "default"}>
                        {variance > 0 ? "+" : ""}
                        {variance.toFixed(0)}%
                      </Badge>
                    )}
                  </div>
                </div>
                <Progress value={(day.spending / 250) * 100} />
              </div>
            );
          })}
        </div>
      </Card>

      {/* Smart Tags */}
      <Card className="p-6">
        <h3 className="font-bold text-lg mb-4">AI-Generated Smart Tags</h3>
        <div className="flex flex-wrap gap-2">
          {[
            { tag: "Impulse Buyer", color: "red" },
            { tag: "Weekend Spender", color: "orange" },
            { tag: "Subscription Heavy", color: "purple" },
            { tag: "Budget Conscious", color: "green" },
            { tag: "Meal Prep Opportunity", color: "blue" },
            { tag: "Seasonal Shopper", color: "indigo" },
          ].map((item, idx) => (
            <Badge key={idx} variant="outline" className="px-3 py-1">
              <Lightbulb className="w-3 h-3 mr-1" />
              {item.tag}
            </Badge>
          ))}
        </div>
      </Card>

      {/* Achievements */}
      <Card className="p-6 bg-gradient-to-br from-yellow-50 to-orange-50">
        <h3 className="font-bold text-lg mb-4">Recent Achievements</h3>
        <div className="grid sm:grid-cols-3 gap-4">
          {[
            { title: "Budget Master", desc: "Stayed under budget 3 months in a row", icon: "🏆" },
            { title: "Saver Pro", desc: "Saved $500 this month", icon: "💰" },
            { title: "Tracker Elite", desc: "Logged 100 transactions", icon: "📊" },
          ].map((achievement, idx) => (
            <div key={idx} className="flex items-center gap-3 p-4 bg-white rounded-lg border">
              <div className="text-3xl">{achievement.icon}</div>
              <div>
                <div className="font-bold">{achievement.title}</div>
                <div className="text-sm text-gray-600">{achievement.desc}</div>
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}
