// Real local Chromium, synthetic DOM, no production browser or remote requests.
import assert from 'node:assert/strict'
import test, { before, after } from 'node:test'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const source = process.env.MUSE_SOURCE_DIR || fileURLToPath(new URL('../../../node3-browser-poc/muse-chat-mcp-test/source/', import.meta.url))
const { driver } = await import(pathToFileURL(path.join(source, 'muse-driver.mjs')))
const { chromium } = await import(pathToFileURL(path.join(source, 'node_modules/playwright-core/index.mjs')))
const Driver = driver.constructor
const fixture = (name) => fs.readFileSync(path.join(here, 'fixtures', name + '.html'), 'utf8')
const logs = (d) => fs.readFileSync(d._detectorLogFile, 'utf8').trim().split('\n').map(JSON.parse)
const decide = (d) => d._serial(() => d._detectApproval({ context: 'acceptance' }))
let browser

before(async () => {
  fs.mkdirSync(path.join(here, 'logs'), { recursive: true })
  let executablePath = process.env.T046_CHROMIUM_EXECUTABLE
  if (!executablePath) {
    const cache = path.join(os.homedir(), '.cache/ms-playwright')
    executablePath = fs.readdirSync(cache).filter((name) => /^chromium-\d+$/.test(name))
      .sort((a, b) => Number(b.split('-')[1]) - Number(a.split('-')[1]))
      .map((name) => path.join(cache, name, 'chrome-linux64/chrome')).find(fs.existsSync)
  }
  browser = await chromium.launch({ executablePath, headless: true, args: ['--no-sandbox'] })
  console.log('Synthetic DOM browser:', browser.version())
})
after(async () => { await browser?.close() })

async function setup(t, name, html = fixture('approval-card')) {
  const ctx = await browser.newContext({ viewport: { width: 1024, height: 768 } })
  t.after(() => ctx.close())
  let loads = 0
  const response = { html }
  await ctx.route('**/*', async (route) => {
    loads++
    await route.fulfill({ contentType: 'text/html; charset=utf-8', body: response.html })
  })
  const d = new Driver()
  d.ctx = ctx
  d.page = await ctx.newPage()
  d._detectorLogFile = path.join(here, 'logs', name + '.jsonl')
  fs.writeFileSync(d._detectorLogFile, '', { mode: 0o600 })
  await d.page.goto('https://t046.invalid/' + name)
  return { d, response, loads: () => loads }
}

for (const [name, expected, signals, conclusion] of [
  ['approval-card', true, { A: true, B: true, C: true }, 'approval_card'],
  ['empty-container', false, { A: true, B: false, C: false }, 'empty_container'],
  ['share-card', true, { A: false, B: false, C: false }, 'external_approval'],
]) {
  test('acceptance: ' + name, async (t) => {
    const { d, loads } = await setup(t, name, fixture(name))
    const result = await decide(d)
    assert.equal(result.needsApproval, expected)
    assert.deepEqual(result.signals, signals)
    assert.equal(result.conclusion, conclusion)
    assert.equal(loads(), 1)
    const decision = logs(d).findLast((event) => event.event === 'decision')
    assert.equal(decision.stable, true)
    assert.equal(decision.samples, 2)
    if (name === 'share-card') assert.deepEqual(result.externalButtons,
      [{ label: '允许一次', visible: true, inComposerViewport: true }])
    console.log(name, JSON.stringify(decision))
  })
}

for (const [name, css] of [
  ['display-none', 'display:none'], ['visibility-hidden', 'visibility:hidden'],
  ['zero-size', 'width:0;height:0;padding:0;border:0;font-size:0'],
  ['offscreen', 'position:fixed;top:1200px'], ['outside-composer', 'position:fixed;top:10px'],
]) {
  test('reject unusable approval button: ' + name, async (t) => {
    const { d } = await setup(t, name)
    await d.page.locator('[data-approval-id] button').first().evaluate((el, css) => { el.style.cssText = css }, css)
    const result = await decide(d)
    assert.deepEqual(result.signals, { A: true, B: true, C: false })
    assert.equal(result.needsApproval, false)
    assert.equal(result.conclusion, 'unavailable_card')
  })
}

test('hidden ancestor and overflow clipping reject the card', async (t) => {
  const { d } = await setup(t, 'ancestor-clipping')
  await d.page.locator('[data-approval-id]').evaluate((el) => { el.style.opacity = '0' })
  assert.equal((await decide(d)).needsApproval, false)
  await d.page.locator('[data-approval-id]').evaluate((el) => {
    el.style.cssText = 'height:1px;overflow:hidden'
  })
  assert.equal((await decide(d)).needsApproval, false)
})

test('B and C must belong to the same approval button', async (t) => {
  const { d } = await setup(t, 'same-button')
  await d.page.locator('[data-approval-id]').evaluate((el) => {
    el.innerHTML = '<button style="visibility:hidden">允许</button><button style="position:fixed;top:1200px">Allow once</button>'
  })
  const result = await decide(d)
  assert.deepEqual(result.signals, { A: true, B: true, C: false })
  assert.equal(result.needsApproval, false)
})

test('ordinary Share/Allow toolbar buttons are not external approvals', async (t) => {
  const { d } = await setup(t, 'toolbar', fixture('empty-container'))
  await d.page.evaluate(() => { document.body.insertAdjacentHTML('beforeend', '<nav><button>Share</button><button>Allow</button></nav>') })
  assert.equal((await decide(d)).needsApproval, false)
})

test('draft text mentioning a pause and ordinary generation are not blocked sends', async (t) => {
  const { d } = await setup(t, 'draft-and-generation', fixture('empty-container'))
  await d.page.locator('textarea').fill('Explain what "Sending is paused" means')
  await d.page.locator('[aria-label="Send"]').evaluate((el) => { el.disabled = false })
  assert.equal((await decide(d)).needsApproval, false)
  await d.page.locator('[aria-label="Send"]').evaluate((el) => { el.disabled = true })
  await d.page.locator('main').evaluate((el) => {
    el.insertAdjacentHTML('beforeend', '<button data-testid="hatch-composer-stop-button">Stop</button>')
  })
  assert.equal((await decide(d)).needsApproval, false)
})

test('polling detects a card appearing between samples before accepting stability', async (t) => {
  const { d } = await setup(t, 'dom-change', fixture('empty-container'))
  await d.page.evaluate(() => { setTimeout(() => {
    document.querySelector('[data-hatch-composer-approval-stack]').innerHTML = '<button>允许</button>'
  }, 60) })
  assert.equal((await decide(d)).needsApproval, true)
  const events = logs(d)
  assert.equal(events[0].signals.B, false)
  assert.ok(events.some((event) => event.sample >= 2 && event.changed && event.signals.B))
  assert.ok(events.findLast((event) => event.event === 'decision').samples >= 3)
})

test('unstable snapshots stop within the short timeout and retain current signals', async (t) => {
  const { d } = await setup(t, 'unstable-timeout')
  const original = d._approvalSnapshot.bind(d)
  let samples = 0
  d._approvalSnapshot = async () => {
    await d.page.locator('[data-approval-id] button').first().evaluate((el, label) => { el.textContent = label }, ++samples % 2 ? '允许' : 'Approve')
    return original()
  }
  const start = Date.now(), result = await decide(d)
  assert.ok(Date.now() - start < 3500)
  assert.equal(result.needsApproval, true)
  const event = logs(d).findLast((item) => item.event === 'decision')
  assert.equal(event.stable, false)
  assert.equal(event.reason, 'unstable_timeout')
})

const paused = fixture('share-card').replace('<button>允许一次</button>', '')
test('contradiction reloads once and discovers a sharing card', async (t) => {
  const { d, response, loads } = await setup(t, 'recovery-success', paused)
  response.html = fixture('share-card')
  assert.equal((await decide(d)).conclusion, 'external_approval')
  assert.equal(loads(), 2)
  const events = logs(d)
  assert.ok(events.some((e) => e.conclusion === 'suspected_share_card' && e.needsApproval))
  assert.deepEqual(events.filter((e) => e.event === 'recovery').map((e) => e.outcome), ['started', 'recovered'])
  assert.ok(events.some((e) => e.event === 'decision' && e.attempt === 1))
})

test('persistent contradiction stays suspected and cannot cause a reload loop', async (t) => {
  const { d, loads } = await setup(t, 'recovery-unresolved', paused)
  assert.equal((await decide(d)).conclusion, 'suspected_share_card')
  assert.equal((await decide(d)).needsApproval, true)
  assert.equal(loads(), 2)
  assert.deepEqual(logs(d).filter((e) => e.event === 'recovery').map((e) => e.outcome), ['started', 'unresolved', 'already_retried'])
})

test('nonempty draft plus disabled Send is a suspected sharing signal', async (t) => {
  const { d } = await setup(t, 'blocked-draft', fixture('empty-container'))
  await d.page.locator('textarea').fill('pending draft')
  // Simulate the same blocked draft surviving reload, without resubmitting it.
  await d.page.context().unroute('**/*')
  await d.page.context().route('**/*', (route) => route.fulfill({ contentType: 'text/html',
    body: fixture('empty-container').replace('<textarea></textarea>', '<textarea>pending draft</textarea>') }))
  const result = await decide(d)
  assert.equal(result.needsApproval, true)
  assert.equal(result.pauseEvidence.blockedDraft, true)
})

test('reload failure retains suspected state with evidence', async (t) => {
  const { d } = await setup(t, 'recovery-failed', paused)
  d.page.reload = async () => { throw new Error('synthetic navigation failure') }
  assert.equal((await decide(d)).needsApproval, true)
  assert.equal(logs(d).findLast((e) => e.event === 'recovery').outcome, 'failed')
})

test('status waits for the serial queue and preserves its public fields', async (t) => {
  const { d } = await setup(t, 'status-serial')
  d.checkAuth = async () => ({ ok: true, viewerId: 'synthetic' })
  d.hasComposer = async () => true
  let done = false
  const prior = d._serial(async () => { await new Promise((r) => setTimeout(r, 80)); done = true })
  const snapshot = d._approvalSnapshot.bind(d)
  d._approvalSnapshot = () => { assert.ok(done); return snapshot() }
  const state = await d.status()
  await prior
  assert.equal(state.needsApproval, true)
  assert.deepEqual(Object.keys(state).sort(), ['browserRunning', 'url', 'loggedIn', 'viewerId', 'composerReady', 'needsApproval', 'profileDir', 'headless'].sort())
})

for (const mode of ['normal-reply', 'approval-during-chat', 'recovery-during-chat']) {
  test('chat integration: ' + mode, async (t) => {
    const html = fixture('empty-container').replace(' disabled', '')
    const { d, response, loads } = await setup(t, mode, html)
    // Navigation is local to the routed fixture. Typing, Enter, DOM reads,
    // detector, real reload and the chat loop all use the source driver.
    d.gotoApp = async () => d.page
    const prompts = []
    await d.page.context().exposeBinding('recordPrompt', (_, value) => { prompts.push(value) })
    await d.page.evaluate((mode) => {
      const editor = document.querySelector('textarea')
      editor.addEventListener('keydown', (event) => {
        if (event.key !== 'Enter') return
        event.preventDefault()
        window.recordPrompt(editor.value)
        editor.value = ''
        if (mode === 'normal-reply') {
          document.body.insertAdjacentHTML('beforeend', '<article data-message-item data-message-role="assistant">Hello in three words.</article>')
        } else if (mode === 'approval-during-chat') {
          document.querySelector('[data-hatch-composer-approval-stack]').innerHTML = '<button>允许</button>'
        } else {
          document.querySelector('main').insertAdjacentHTML('beforeend', '<p>Sending is paused</p>')
        }
      })
    }, mode)
    if (mode === 'recovery-during-chat') response.html = fixture('share-card')
    const prompt = 'verbatim first line\nsecond line: 允许 / ### markers stay as supplied'
    const chunks = []
    const start = Date.now()
    const result = await d.chatStream(prompt, { timeoutMs: 8000, onDelta: (text) => chunks.push(text) })
    assert.deepEqual(prompts, [prompt])
    assert.equal(result.timedOut, undefined)
    if (mode === 'normal-reply') {
      assert.equal(result.reply, 'Hello in three words.')
      assert.equal(result.needsApproval, undefined)
      assert.ok(chunks.length > 0)
      for (let i = 1; i < chunks.length; i++) assert.ok(chunks[i].startsWith(chunks[i - 1]))
    } else {
      assert.equal(result.needsApproval, true)
      assert.ok(Date.now() - start < 5000)
    }
    assert.equal(loads(), mode === 'recovery-during-chat' ? 2 : 1)
  })
}
