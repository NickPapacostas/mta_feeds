// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

let plugin = require('tailwindcss/plugin')

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    plugin(({addVariant}) => addVariant('phx-no-feedback', ['&.phx-no-feedback', '.phx-no-feedback &'])),
    plugin(({addVariant}) => addVariant('phx-click-loading', ['&.phx-click-loading', '.phx-click-loading &'])),
    plugin(({addVariant}) => addVariant('phx-submit-loading', ['&.phx-submit-loading', '.phx-submit-loading &'])),
    plugin(({addVariant}) => addVariant('phx-change-loading', ['&.phx-change-loading', '.phx-change-loading &']))
  ],
  safelist: [
    "bg-red-400",
    "bg-green-600",
    "bg-cyan-400",
    "bg-orange-400",
    "bg-yellow-400",
    "bg-emerald-400",
    "bg-zinc-400",
    "bg-slate-400",
    "bg-black-400",
    "bg-violet-400",
    "bg-slate",
    "ring-red-400",
    "ring-green-600",
    "ring-cyan-400",
    "ring-orange-400",
    "ring-yellow-400",
    "ring-emerald-400",
    "ring-zinc-400",
    "ring-slate-400",
    "ring-black-400",
    "ring-violet-400"
  ]
}
