import { RouterProvider } from "react-router";
import { router } from "./routes";
import { Toaster } from "./components/ui/sonner";
import { AuthProvider } from "./contexts/AuthContext";
import { LanguageProvider } from "../contexts/LanguageContext";
import { RoleProvider } from "./contexts/RoleContext";
import "../i18n/config";

export default function App() {
  return (
    <AuthProvider>
      <LanguageProvider>
        <RoleProvider>
          <RouterProvider router={router} />
          <Toaster />
        </RoleProvider>
      </LanguageProvider>
    </AuthProvider>
  );
}
