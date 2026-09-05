# Plato Web

This is the landing page and informational website for the **Plato** project, deployed via Vercel.

## Tech Stack
- **Build Tool:** [Vite](https://vitejs.dev/)
- **Styling:** [Tailwind CSS](https://tailwindcss.com/)
- **Animations:** [AOS (Animate On Scroll)](https://michalsnik.github.io/aos/)
- **Icons:** [Lucide Icons](https://lucide.dev/)

## Project Structure
This is a multi-page Vite project. The entry points are configured in `vite.config.js`:
- `index.html`: Home page
- `about.html`: About Us page
- `terms.html`: Terms of Service
- `eula.html`: End User License Agreement
- `features.html`: Features overview
- `library.html`: Exercise library

Other important files:
- `style.css`: Main Tailwind CSS entry file.
- `main.js`: Main JavaScript entry file (initializes AOS, Lucide, mobile menu, etc.).
- `library.js` & `exercises_data.js`: Logic and data for the library page.
- `tailwind.config.js`: Tailwind configuration.
- `vite.config.js`: Vite build configuration.

## Available Scripts

In the project directory, you can run:

### `npm run dev`
Runs the app in the development mode.
Open [http://localhost:5173](http://localhost:5173) to view it in your browser.

### `npm run build`
Builds the app for production to the `dist` folder.
It correctly bundles all the HTML files defined in the Vite config.

### `npm run preview`
Locally preview the production build after running `npm run build`.

## Deployment
This project is configured to be deployed on **Vercel**. 

- **Clean URLs** are enabled via the `vercel.json` configuration file. All internal HTML links (`href`) have been optimized to point directly to paths without `.html` (e.g., `/library` instead of `library.html`). Vercel will automatically serve the corresponding HTML file while keeping the URL clean.
