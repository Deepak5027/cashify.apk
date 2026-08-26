import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import apiClient from '../utils/apiClient';
import { useAuth } from '../app/contexts/AuthContext';

interface LanguageContextType {
  currentLanguage: string;
  changeLanguage: (lang: string) => Promise<void>;
  t: (key: string) => string;
  languagePreferenceSet: boolean;
  setLanguagePreferenceSet: (value: boolean) => void;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

function getLanguagePreferenceKey(email?: string) {
  return `financeai_lang_set_${email || 'guest'}`;
}

export function LanguageProvider({ children }: { children: ReactNode }) {
  const { i18n, t } = useTranslation();
  const { user } = useAuth();
  const [languagePreferenceSet, setLanguagePreferenceSetState] = useState<boolean>(() => {
    const key = getLanguagePreferenceKey(user?.email);
    return localStorage.getItem(key) === 'true';
  });

  useEffect(() => {
    // Reload preference when user changes
    const key = getLanguagePreferenceKey(user?.email);
    setLanguagePreferenceSetState(localStorage.getItem(key) === 'true');
  }, [user?.email]);

  useEffect(() => {
    // Load saved language preference
    const loadLanguagePreference = async () => {
      if (user) {
        try {
          const res = await apiClient.get(`/api/kv/${encodeURIComponent(`user_language_${user.id}`)}`);
          if (res?.data?.value) {
            await i18n.changeLanguage(res.data.value);
          }
        } catch (error) {
          console.log('No saved language preference');
        }
      }
    };

    loadLanguagePreference();
  }, [user, i18n]);

  const setLanguagePreferenceSet = (value: boolean) => {
    const key = getLanguagePreferenceKey(user?.email);
    if (value) {
      localStorage.setItem(key, 'true');
    } else {
      localStorage.removeItem(key);
    }
    setLanguagePreferenceSetState(value);
  };

  const changeLanguage = async (lang: string) => {
    await i18n.changeLanguage(lang);

    if (user) {
      try {
        await apiClient.post('/api/kv', { key: `user_language_${user.id}`, value: lang });
      } catch (error) {
        console.error('Failed to save language preference:', error);
      }
    }

    // Mark language as set
    setLanguagePreferenceSet(true);
  };

  return (
    <LanguageContext.Provider value={{
      currentLanguage: i18n.language,
      changeLanguage,
      t,
      languagePreferenceSet,
      setLanguagePreferenceSet
    }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within LanguageProvider');
  }
  return context;
}
