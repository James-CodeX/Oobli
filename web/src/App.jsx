import { Footer, Header } from './components/Chrome.jsx';
import { Anywhere } from './sections/Anywhere.jsx';
import { CategoryStrip } from './sections/CategoryStrip.jsx';
import { Faq, FinalCta, Privacy } from './sections/Closing.jsx';
import { Feature } from './sections/Feature.jsx';
import { GoalSaver } from './sections/GoalSaver.jsx';
import { Hero } from './sections/Hero.jsx';
import { OobliSays } from './sections/OobliSays.jsx';
import { PlanSlider } from './sections/PlanSlider.jsx';
import { QuickSortDemo } from './sections/QuickSortDemo.jsx';
import { SmsPhone } from './sections/SmsPhone.jsx';
import { Wrapped } from './sections/Wrapped.jsx';

export function App() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <CategoryStrip />
        <Feature id="how" title="reads your m-pesa for you" art={<SmsPhone />}>
          <p>Every M-Pesa and bank confirmation turns into a clean, sorted transaction: Tills, Paybills, Pochi la Biashara, Send Money and bank transfers. No typing, no spreadsheets.</p>
        </Feature>
        <Feature id="sort" title="sort anything in one tap" art={<QuickSortDemo />} flip>
          <p>When Oobli isn't sure, Quick sort shows you the transaction and every category. One tap files it and jumps to the next, and Oobli remembers that merchant from then on. <b>Try it →</b></p>
        </Feature>
        <Feature title="oobli says…" art={<OobliSays />}>
          <p>Friendly nudges that catch subscriptions, spending spikes and Pochi patterns before they cost you, written by AI from your own numbers.</p>
        </Feature>
        <Feature id="plans" title="plans that fit your pay" art={<PlanSlider />} flip tint="blue">
          <p>Tell Oobli what you expect to earn and get a monthly plan for needs, savings, flex and emergencies, tuned to how you actually spend. Drag the slider.</p>
        </Feature>
        <Feature title="stay motivated" art={<GoalSaver />}>
          <p>Set goals, keep streaks and watch progress rings fill up. Saving feels less like a chore and more like a game. Go on, tap save.</p>
        </Feature>
        <Anywhere />
        <Wrapped />
        <Privacy />
        <Faq />
        <FinalCta />
      </main>
      <Footer />
    </>
  );
}
