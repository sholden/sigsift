import * as Turbo from '@hotwired/turbo'
import { Application } from '@hotwired/stimulus'

import '~/index.css'

Turbo.start()

const application = Application.start()
const controllers = import.meta.glob('../controllers/**/*_controller.ts', { eager: true })
Object.entries(controllers).forEach(([path, mod]: [string, any]) => {
  const name = path
    .replace('../controllers/', '')
    .replace('_controller.ts', '')
    .replace(/\//g, '--')
  application.register(name, mod.default)
})
