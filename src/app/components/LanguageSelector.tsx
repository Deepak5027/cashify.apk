import { useState } from 'react';
import { Card } from './ui/card';
import { Button } from './ui/button';
import { Globe, Check } from 'lucide-react';
import { motion } from 'motion/react';

interface LanguageSelectorProps {
  onSelect: (language: string) => void;
}

const languages = [
  {
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
    description: 'Use English for all app content'
  },
  {
    code: 'ta',
    name: 'Tamil',
    nativeName: 'தமிழ்',
    flag: '🇮🇳',
    description: 'அனைத்து பயன்பாட்டு உள்ளடக்கத்திற்கும் தமிழைப் பயன்படுத்தவும்'
  },
  {
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिन्दी',
    flag: '🇮🇳',
    description: 'सभी ऐप सामग्री के लिए हिंदी का उपयोग करें'
  }
];

export function LanguageSelector({ onSelect }: LanguageSelectorProps) {
  const [selected, setSelected] = useState<string | null>(null);

  const handleSelect = (code: string) => {
    setSelected(code);
  };

  const handleContinue = () => {
    if (selected) {
      onSelect(selected);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4" style={{ background: '#080c14' }}>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-2xl"
      >
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl mb-4"
            style={{ background: 'linear-gradient(135deg, #10b981, #3b82f6)' }}>
            <Globe className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-3xl font-bold mb-2" style={{ color: '#e8edf5' }}>
            Choose Your Language
          </h1>
          <p className="text-lg" style={{ color: '#6b7ca0' }}>
            Select your preferred language for the entire app
          </p>
        </div>

        <div className="grid gap-4 mb-6">
          {languages.map((lang, idx) => (
            <motion.div
              key={lang.code}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: idx * 0.1 }}
            >
              <Card
                className={`p-6 cursor-pointer transition-all ${
                  selected === lang.code ? 'ring-2 ring-green-500' : ''
                }`}
                onClick={() => handleSelect(lang.code)}
                style={{
                  background: selected === lang.code ? 'rgba(16,185,129,0.08)' : 'rgba(14,20,35,0.75)',
                  border: selected === lang.code ? '2px solid #10b981' : '1px solid rgba(255,255,255,0.07)',
                  backdropFilter: 'blur(16px)'
                }}
              >
                <div className="flex items-center gap-4">
                  <div className="text-4xl">{lang.flag}</div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <h3 className="text-xl font-bold" style={{ color: '#e8edf5' }}>
                        {lang.nativeName}
                      </h3>
                      <span className="text-sm" style={{ color: '#6b7ca0' }}>
                        ({lang.name})
                      </span>
                    </div>
                    <p className="text-sm mt-1" style={{ color: '#94a3b8' }}>
                      {lang.description}
                    </p>
                  </div>
                  {selected === lang.code && (
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      className="w-8 h-8 rounded-full flex items-center justify-center"
                      style={{ background: '#10b981' }}
                    >
                      <Check className="w-5 h-5 text-white" />
                    </motion.div>
                  )}
                </div>
              </Card>
            </motion.div>
          ))}
        </div>

        <Button
          onClick={handleContinue}
          disabled={!selected}
          className="w-full py-6 text-lg font-semibold"
          style={{
            background: selected ? 'linear-gradient(135deg, #10b981, #3b82f6)' : 'rgba(107,124,160,0.3)',
            color: '#fff'
          }}
        >
          Continue to Dashboard →
        </Button>

        <p className="text-center text-sm mt-4" style={{ color: '#6b7ca0' }}>
          You can change this anytime in Profile Settings
        </p>
      </motion.div>
    </div>
  );
}
