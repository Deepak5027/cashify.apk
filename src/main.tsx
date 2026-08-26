import { createRoot } from "react-dom/client";
import App from "./app/App";
import "./styles/index.css";

// Clear old service workers on development/localhost to prevent stale cached bundles
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then((registrations) => {
    for (const registration of registrations) {
      registration.unregister();
    }
  });
  if ('caches' in window) {
    caches.keys().then((keys) => {
      keys.forEach((key) => caches.delete(key));
    });
  }
}

createRoot(document.getElementById("root")!).render(<App />);