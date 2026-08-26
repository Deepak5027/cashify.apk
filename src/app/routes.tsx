import { createBrowserRouter, Navigate } from "react-router";
import Root from "./pages/Root";
import Landing from "./pages/Landing";
import Login from "./pages/Login";
import Signup from "./pages/Signup";
import ForgotPassword from "./pages/ForgotPassword";
import EmailVerification from "./pages/EmailVerification";
import AuthCallback from "./pages/AuthCallback";
import Dashboard from "./pages/Dashboard";
import Transactions from "./pages/Transactions";
import Budget from "./pages/Budget";
import Alerts from "./pages/Alerts";
import Scanner from "./pages/Scanner";
import Analytics from "./pages/Analytics";
import Profile from "./pages/Profile";
import VoiceEntry from "./pages/VoiceEntry";
import SmartInsights from "./pages/SmartInsights";
import Goals from "./pages/Goals";
import Chatbot from "./pages/Chatbot";
import BankImport from "./pages/BankImport";
import UpiImport from "./pages/UpiImport";
import Calculator from "./pages/Calculator";
import AIPredictions from "./pages/AIPredictions";
import Settings from "./pages/Settings";
import HowItWorks from "./pages/HowItWorks";
import AdminAnalytics from "./pages/AdminAnalytics";
import NotFound from "./pages/NotFound";
import ProtectedRoute from "./components/ProtectedRoute";
import ErrorBoundary from "./components/ErrorBoundary";

export const router = createBrowserRouter([
  {
    path: "/",
    element: (
      <ErrorBoundary>
        <Landing />
      </ErrorBoundary>
    ),
  },
  {
    path: "/login",
    element: (
      <ErrorBoundary>
        <Login />
      </ErrorBoundary>
    ),
  },
  {
    path: "/signup",
    element: (
      <ErrorBoundary>
        <Signup />
      </ErrorBoundary>
    ),
  },
  {
    path: "/forgot-password",
    element: (
      <ErrorBoundary>
        <ForgotPassword />
      </ErrorBoundary>
    ),
  },
  {
    path: "/verify-email",
    element: (
      <ErrorBoundary>
        <EmailVerification />
      </ErrorBoundary>
    ),
  },
  {
    path: "/auth/callback",
    element: <AuthCallback />,
  },
  {
    path: "/app",
    element: (
      <ErrorBoundary>
        <ProtectedRoute>
          <Root />
        </ProtectedRoute>
      </ErrorBoundary>
    ),
    children: [
      { index: true, element: <Dashboard /> },
      { path: "transactions", element: <Transactions /> },
      { path: "budget", element: <Budget /> },
      { path: "alerts", element: <Alerts /> },
      { path: "scanner", element: <Scanner /> },
      { path: "analytics", element: <Analytics /> },
      { path: "voice", element: <VoiceEntry /> },
      { path: "insights", element: <SmartInsights /> },
      { path: "goals", element: <Goals /> },
      { path: "chatbot", element: <Chatbot /> },
      { path: "import", element: <BankImport /> },
      { path: "upi-import", element: <UpiImport /> },
      { path: "calculator", element: <Calculator /> },
      { path: "predictions", element: <AIPredictions /> },
      { path: "how-it-works", element: <HowItWorks /> },
      { path: "admin", element: <AdminAnalytics /> },
      { path: "profile", element: <Profile /> },
      { path: "settings", element: <Settings /> },
    ],
  },
  {
    path: "*",
    element: <NotFound />,
  },
]);