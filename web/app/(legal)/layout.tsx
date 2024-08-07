import { RootProvider } from 'fumadocs-ui/provider';
import type { ReactNode } from 'react';
 
export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}