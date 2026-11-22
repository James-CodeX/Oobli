import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { LegalPage } from './components/LegalPage.jsx';
import { CONTACT_EMAIL, CONTACT_URL } from './config.js';
import './styles.css';

const sections = [
  { id: 'summary', title: 'Summary', body: (
    <ul className="checks">
      <li>Oobli only reads SMS from financial senders (like M-Pesa and banks). Everything else is skipped on your phone.</li>
      <li>We store your transactions so you can see them on any device, locked to your account.</li>
      <li>We never sell your data and we don't show ads.</li>
      <li>You can ask us to delete everything at any time.</li>
    </ul>
  ) },
  { id: 'collect', title: 'What we collect', body: (
    <>
      <p><b>Account details:</b> your name, email address and password (stored as a secure hash by our backend provider), plus app settings such as your monthly income estimate, focus goal and theme.</p>
      <p><b>Financial SMS:</b> with your permission, the app reads your SMS inbox <b>on your phone</b> and keeps only messages from known financial senders. From each one it extracts the amount, direction (in or out), merchant or sender name, M-Pesa product, date, reference code and balance. The text of that financial message is saved with the transaction so you can check it later. Personal conversations are never read into the app or uploaded.</p>
      <p><b>Things you add:</b> manual transactions, notes, category corrections, plans and savings goals.</p>
      <p><b>Technical data:</b> basic logs (such as error messages and request times) needed to keep the Service secure and working.</p>
    </>
  ) },
  { id: 'use', title: 'How we use it', body: (
    <ul>
      <li>To show your transactions, charts, plans, goals and monthly Wrapped.</li>
      <li>To categorise transactions, remembering the corrections you make for each merchant.</li>
      <li>To generate "Oobli says…" insights, plans and recaps.</li>
      <li>To secure the Service, prevent abuse and fix problems.</li>
    </ul>
  ) },
  { id: 'ai', title: 'Artificial intelligence', body: (
    <>
      <p>Oobli first uses rules on your phone. Only when those can't decide does it ask our AI service, which runs on our servers and uses Google's Gemini models. What is sent:</p>
      <ul>
        <li><b>Categorising:</b> the merchant name, amount, M-Pesa product and direction of the transactions being sorted.</li>
        <li><b>Unrecognised messages:</b> the text of a financial SMS that our parser could not read.</li>
        <li><b>Insights, plans and Wrapped:</b> summaries such as category totals and trends, not your whole message history.</li>
      </ul>
      <p>Requests are sent only for signed-in users, and Google processes them under its Gemini API terms. AI suggestions can be wrong, and you can always correct them.</p>
    </>
  ) },
  { id: 'storage', title: 'Where your data is stored', body: <p>Your account and transactions are stored with Appwrite Cloud in its Singapore region. Each record is restricted so that only your account can read or change it. Data is encrypted in transit (HTTPS). Because our servers are outside Kenya, we rely on the safeguards the Data Protection Act, 2019 requires for cross-border transfers.</p> },
  { id: 'share', title: 'Who we share it with', body: (
    <>
      <p>We share data only with service providers that help us run Oobli, and only as needed:</p>
      <ul>
        <li><b>Appwrite</b>: authentication, database and server functions.</li>
        <li><b>Google (Gemini API)</b>: AI categorisation and insights, as described above.</li>
      </ul>
      <p>We may disclose information if the law requires it. We do not sell personal data, and we do not share it with advertisers, lenders or data brokers.</p>
    </>
  ) },
  { id: 'device', title: 'Permissions and data on your device', body: <p>Oobli asks for <b>SMS (read)</b> permission to import financial messages, and <b>Internet</b> to sync. You can turn SMS access off in Settings at any time and still add transactions by hand. The app keeps a small cache on your phone, such as your session and settings. Signing out clears it.</p> },
  { id: 'retention', title: 'How long we keep it', body: <p>We keep your data while your account is active. If you ask us to delete your account, we delete your profile, transactions, rules, plans and goals within 30 days, except for anything we must keep by law. Backups are overwritten on a rolling basis.</p> },
  { id: 'rights', title: 'Your rights', body: (
    <>
      <p>Under Kenya's Data Protection Act, 2019 you can ask to access, correct or delete your personal data, object to or restrict processing, and withdraw consent (for example, by turning off SMS access). To make a request, email <a href={CONTACT_URL}>{CONTACT_EMAIL}</a>. We will respond within the time the law requires.</p>
      <p>If you're unhappy with how we handle your data, you can complain to the Office of the Data Protection Commissioner (ODPC).</p>
    </>
  ) },
  { id: 'children', title: 'Children', body: <p>Oobli is for adults aged 18 and over. We don't knowingly collect data from children. If you believe a child has used Oobli, contact us and we'll delete the account.</p> },
  { id: 'changes', title: 'Changes to this policy', body: <p>If we change how we use your data in a significant way, we'll tell you in the app before the change applies. The date at the top shows when this policy was last updated.</p> },
  { id: 'contact', title: 'Contact', body: <p>Questions about privacy? Email <a href={CONTACT_URL}>{CONTACT_EMAIL}</a>.</p> },
];

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <LegalPage
      title="Privacy Policy"
      intro="Your money messages are personal. This policy explains exactly what Oobli reads, what it stores, what our AI sees and the control you have."
      sections={sections}
    />
  </StrictMode>,
);
