import { useState, useEffect } from 'react'
import { sb } from '../lib/supabase'
import { useAuth } from '../store/useAuth'
import { useToast } from '../store/useToast'
import { Link } from 'react-router-dom'
import Nav from '../components/Nav'
import Modal from '../components/Modal'

const GROUP = { 1: 'Fryzjerstwo', 2: 'Kosmetyka', 3: 'Paznokcie', 4: 'Masaż i SPA', 5: 'Medycyna estetyczna' }
const VOIVODESHIPS = ['mazowieckie','małopolskie','wielkopolskie','śląskie','dolnośląskie','łódzkie','pomorskie','kujawsko-pomorskie','warmińsko-mazurskie','podkarpackie','lubelskie','podlaskie','zachodniopomorskie','lubuskie','świętokrzyskie','opolskie']

function priceStr(sv) {
  if (!sv.price_from && !sv.price_to) return 'zapytaj'
  if (sv.price_from && sv.price_to && sv.price_to !== sv.price_from) return `${sv.price_from}–${sv.price_to} zł`
  return `od ${sv.price_from ?? sv.price_to} zł`
}

/* ── AUTH FORM ─────────────────────────────────────────────────── */
function AuthForm() {
  const toast = useToast(s => s.toast)
  const [mode, setMode] = useState('login')
  const [form, setForm] = useState({ email: '', password: '', fullName: '' })
  const [err, setErr]   = useState('')
  const [busy, setBusy] = useState(false)

  async function submit(e) {
    e.preventDefault()
    setBusy(true); setErr('')
    let error
    if (mode === 'login') {
      ;({ error } = await sb.auth.signInWithPassword({ email: form.email, password: form.password }))
    } else {
      ;({ error } = await sb.auth.signUp({ email: form.email, password: form.password, options: { data: { full_name: form.fullName } } }))
      if (!error) {
        const uid = (await sb.auth.getUser()).data.user?.id
        if (uid) await sb.from('katalog_profiles').upsert({ id: uid, full_name: form.fullName })
        toast('Sprawdź e-mail i potwierdź konto.', 'info', 7000)
      }
    }
    if (error) setErr(error.message)
    setBusy(false)
  }

  const tabStyle = active => ({
    flex: 1, padding: '.45rem', border: 'none', borderRadius: '.45rem',
    fontSize: '.85rem', fontWeight: 700, cursor: 'pointer',
    background: active ? '#fff' : 'transparent',
    color: active ? '#7c3aed' : '#64748b',
    boxShadow: active ? '0 1px 3px rgba(0,0,0,.08)' : 'none',
  })

  return (
    <div style={{ minHeight: '80vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
      <div className="card" style={{ padding: '2rem', width: '100%', maxWidth: 420 }}>
        <h1 style={{ fontSize: '1.4rem', color: '#4c1d95', marginBottom: '.25rem' }}>Panel właściciela</h1>
        <p style={{ fontSize: '.875rem', color: '#64748b', marginBottom: '1.5rem' }}>Zaloguj się lub utwórz konto, aby zarządzać salonem.</p>

        <div style={{ display: 'flex', gap: '.4rem', background: '#f1f5f9', borderRadius: '.6rem', padding: '.25rem', marginBottom: '1.5rem' }}>
          <button onClick={() => setMode('login')}    style={tabStyle(mode === 'login')}>Logowanie</button>
          <button onClick={() => setMode('register')} style={tabStyle(mode === 'register')}>Rejestracja</button>
        </div>

        <form onSubmit={submit}>
          {mode === 'register' && (
            <div style={{ marginBottom: '1rem' }}>
              <label className="label">Imię i nazwisko</label>
              <input className="input" value={form.fullName} onChange={e => setForm(f => ({ ...f, fullName: e.target.value }))} placeholder="Jan Kowalski" autoComplete="name" />
            </div>
          )}
          <div style={{ marginBottom: '1rem' }}>
            <label className="label">E-mail</label>
            <input className="input" type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} required placeholder="jan@example.com" />
          </div>
          <div style={{ marginBottom: '1.5rem' }}>
            <label className="label">Hasło</label>
            <input className="input" type="password" value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))} required minLength={6} placeholder="••••••••" />
          </div>
          {err && <p style={{ color: '#dc2626', fontSize: '.8rem', marginBottom: '.75rem' }}>{err}</p>}
          <button type="submit" disabled={busy} className="btn btn-primary" style={{ width: '100%', justifyContent: 'center', padding: '.7rem' }}>
            {busy ? '...' : mode === 'login' ? 'Zaloguj się' : 'Utwórz konto'}
          </button>
        </form>
      </div>
    </div>
  )
}

/* ── SERVICE MODAL ──────────────────────────────────────────────── */
function ServiceModal({ service, salonId, onClose, onSaved }) {
  const toast = useToast(s => s.toast)
  const [form, setForm] = useState({
    service_name: service?.service_name ?? '',
    group_id:     service?.group_id ?? '',
    price_from:   service?.price_from ?? '',
    price_to:     service?.price_to ?? '',
    duration_min: service?.duration_min ?? '',
  })
  const [busy, setBusy] = useState(false)

  async function submit(e) {
    e.preventDefault(); setBusy(true)
    const payload = {
      salon_id: salonId,
      service_name: form.service_name,
      group_id:     form.group_id ? parseInt(form.group_id) : null,
      price_from:   form.price_from ? parseInt(form.price_from) : null,
      price_to:     form.price_to   ? parseInt(form.price_to)   : null,
      duration_min: form.duration_min ? parseInt(form.duration_min) : null,
      is_available: true,
    }
    const { error } = service?.id
      ? await sb.from('salon_services').update(payload).eq('id', service.id)
      : await sb.from('salon_services').insert(payload)
    setBusy(false)
    if (error) { toast(error.message, 'error'); return }
    toast('Zabieg zapisany!', 'success')
    onSaved()
  }

  const f = (key, num) => e => setForm(prev => ({ ...prev, [key]: num ? e.target.value.replace(/\D/g, '') : e.target.value }))

  return (
    <Modal onClose={onClose}>
      <h2 style={{ fontSize: '1.1rem', color: '#4c1d95', marginBottom: '1.25rem' }}>{service?.id ? 'Edytuj zabieg' : 'Nowy zabieg'}</h2>
      <form onSubmit={submit}>
        <div style={{ marginBottom: '1rem' }}>
          <label className="label">Nazwa zabiegu *</label>
          <input className="input" value={form.service_name} onChange={f('service_name')} required placeholder="np. Manicure hybrydowy" />
        </div>
        <div style={{ marginBottom: '1rem' }}>
          <label className="label">Grupa</label>
          <select className="input" value={form.group_id} onChange={f('group_id')}>
            <option value="">— wybierz —</option>
            {Object.entries(GROUP).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
          </select>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '.75rem', marginBottom: '1.5rem' }}>
          {[['price_from','Cena od (zł)','100'],['price_to','Cena do (zł)','150'],['duration_min','Czas (min)','60']].map(([key, label, ph]) => (
            <div key={key}>
              <label className="label">{label}</label>
              <input className="input" type="number" value={form[key]} onChange={f(key, true)} min="0" placeholder={ph} />
            </div>
          ))}
        </div>
        <button type="submit" disabled={busy} className="btn btn-primary">{busy ? '...' : 'Zapisz zabieg'}</button>
      </form>
    </Modal>
  )
}

/* ── DASHBOARD ──────────────────────────────────────────────────── */
function Dashboard({ user }) {
  const toast    = useToast(s => s.toast)
  const signOut  = useAuth(s => s.signOut)
  const [tab, setTab]         = useState(0)
  const [salon, setSalon]     = useState(null)
  const [services, setServices] = useState([])
  const [photos, setPhotos]   = useState([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving]   = useState(false)
  const [modal, setModal]     = useState(null) // null | 'new' | service object

  async function load() {
    setLoading(true)
    const { data: s } = await sb.from('salons').select('*').eq('owner_id', user.id).maybeSingle()
    setSalon(s ?? null)
    const [{ data: sv }, { data: ph }] = await Promise.all([
      s ? sb.from('salon_services').select('*').eq('salon_id', s.id).order('created_at') : { data: [] },
      s ? sb.from('salon_photos').select('*').eq('salon_id', s.id).order('sort_order')   : { data: [] },
    ])
    setServices(sv ?? [])
    setPhotos(ph ?? [])
    setLoading(false)
  }

  useEffect(() => { load() }, [user.id])

  /* PROFILE FORM */
  const [form, setForm] = useState(null)
  useEffect(() => {
    if (!loading) setForm(salon ? { ...salon } : {
      name: '', city: '', tagline: '', street: '', postal_code: '', voivodeship: '',
      lat: '', lng: '', phone: '', email_contact: '', website: '',
      instagram_url: '', facebook_url: '', description: '', status: 'draft',
    })
  }, [loading, salon])

  async function saveSalon(e) {
    e.preventDefault(); setSaving(true)
    const payload = {
      owner_id: user.id,
      ...form,
      lat:  parseFloat(form.lat)  || null,
      lng:  parseFloat(form.lng)  || null,
      slug: form.name.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,''),
    }
    let error
    if (salon) {
      ;({ error } = await sb.from('salons').update(payload).eq('id', salon.id))
    } else {
      const { data, error: ie } = await sb.from('salons').insert(payload).select().single()
      error = ie
      if (!error) setSalon(data)
    }
    setSaving(false)
    if (error) toast(error.message, 'error')
    else { toast('Profil zapisany!', 'success'); load() }
  }

  /* PHOTOS */
  const [uploading, setUploading] = useState(false)
  const [uploadPct, setUploadPct] = useState(0)

  async function uploadPhotos(files) {
    if (!salon || !files.length) return
    setUploading(true); setUploadPct(0)
    let done = 0
    for (const file of files) {
      const ext  = file.name.split('.').pop().toLowerCase()
      const path = `${salon.id}/${crypto.randomUUID()}.${ext}`
      const { error: upErr } = await sb.storage.from('salon-photos').upload(path, file, { upsert: true })
      if (upErr) { toast(`Błąd: ${upErr.message}`, 'error'); done++; continue }
      const { data: { publicUrl } } = sb.storage.from('salon-photos').getPublicUrl(path)
      const isCover = done === 0 && photos.length === 0
      await sb.from('salon_photos').insert({ salon_id: salon.id, url: publicUrl, is_cover: isCover, sort_order: 99 })
      done++
      setUploadPct(Math.round((done / files.length) * 100))
    }
    setUploading(false)
    toast(`Dodano ${done} zdjęć!`, 'success')
    load(); setTab(2)
  }

  async function setCover(id) {
    await sb.from('salon_photos').update({ is_cover: false }).eq('salon_id', salon.id)
    await sb.from('salon_photos').update({ is_cover: true }).eq('id', id)
    toast('Okładka ustawiona.', 'success'); load(); setTab(2)
  }

  async function deletePhoto(id, url) {
    if (!confirm('Usunąć to zdjęcie?')) return
    const path = url.split('/salon-photos/').pop()
    if (path) await sb.storage.from('salon-photos').remove([path])
    await sb.from('salon_photos').delete().eq('id', id)
    toast('Zdjęcie usunięte.', 'info'); load(); setTab(2)
  }

  async function deleteService(id) {
    if (!confirm('Usunąć ten zabieg?')) return
    const { error } = await sb.from('salon_services').delete().eq('id', id)
    if (error) toast(error.message, 'error')
    else { toast('Zabieg usunięty.', 'info'); load(); setTab(1) }
  }

  if (loading || !form) return <div className="spinner" />

  const tabBtnStyle = active => ({
    padding: '.6rem 1.1rem', border: 'none', background: 'none', fontFamily: 'inherit',
    fontSize: '.875rem', fontWeight: 700, cursor: 'pointer',
    color: active ? '#7c3aed' : '#64748b',
    borderBottom: `2px solid ${active ? '#7c3aed' : 'transparent'}`,
    marginBottom: -2, transition: '.15s',
  })

  const field = key => ({ value: form[key] ?? '', onChange: e => setForm(f => ({ ...f, [key]: e.target.value })), className: 'input' })

  return (
    <div className="container" style={{ paddingTop: '2rem', paddingBottom: '3rem', maxWidth: 860 }}>

      {/* HEADER */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', flexWrap: 'wrap', gap: '1rem', marginBottom: '2rem' }}>
        <div>
          <h1 style={{ fontSize: '1.5rem', color: '#4c1d95' }}>{salon?.name ?? 'Mój salon'}</h1>
          <p style={{ fontSize: '.82rem', color: '#64748b', marginTop: '.2rem' }}>
            {user.email} · <button onClick={signOut} style={{ background: 'none', border: 'none', color: '#dc2626', fontSize: '.82rem', fontWeight: 700, cursor: 'pointer' }}>Wyloguj</button>
          </p>
        </div>
        {salon && <Link to={`/salon/${salon.id}`} target="_blank" className="btn btn-outline" style={{ fontSize: '.82rem' }}>👁 Podgląd profilu</Link>}
      </div>

      {/* TABS */}
      <div style={{ display: 'flex', gap: '.25rem', borderBottom: '2px solid #e2e8f0', marginBottom: '1.75rem' }}>
        {['Profil salonu', 'Zabiegi', 'Zdjęcia'].map((t, i) => (
          <button key={i} onClick={() => setTab(i)} style={tabBtnStyle(tab === i)}>
            {t}
            {i === 1 && <span className="badge" style={{ marginLeft: '.35rem', fontSize: '.65rem' }}>{services.length}</span>}
            {i === 2 && <span className="badge" style={{ marginLeft: '.35rem', fontSize: '.65rem' }}>{photos.length}</span>}
          </button>
        ))}
      </div>

      {/* TAB 0 — PROFIL */}
      {tab === 0 && (
        <form onSubmit={saveSalon}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            <div><label className="label">Nazwa salonu *</label><input {...field('name')} required /></div>
            <div><label className="label">Miasto *</label><input {...field('city')} required placeholder="np. Warszawa" /></div>
          </div>
          <div style={{ marginBottom: '1rem' }}><label className="label">Hasło reklamowe</label><input {...field('tagline')} placeholder="np. Ekskluzywny salon w centrum" /></div>
          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            <div><label className="label">Ulica i numer</label><input {...field('street')} placeholder="ul. Przykładowa 1" /></div>
            <div><label className="label">Kod pocztowy</label><input {...field('postal_code')} placeholder="00-001" /></div>
          </div>
          <div style={{ marginBottom: '1rem' }}>
            <label className="label">Województwo</label>
            <select {...field('voivodeship')} className="input">
              <option value="">— wybierz —</option>
              {VOIVODESHIPS.map(v => <option key={v} value={v}>{v}</option>)}
            </select>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            <div><label className="label">Lat</label><input {...field('lat')} type="number" step="any" placeholder="52.2297" /></div>
            <div><label className="label">Lng</label><input {...field('lng')} type="number" step="any" placeholder="21.0122" /></div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            <div><label className="label">Telefon</label><input {...field('phone')} type="tel" placeholder="+48 000 000 000" /></div>
            <div><label className="label">E-mail kontaktowy</label><input {...field('email_contact')} type="email" placeholder="salon@example.com" /></div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            <div><label className="label">Strona www</label><input {...field('website')} type="url" placeholder="https://..." /></div>
            <div><label className="label">Instagram</label><input {...field('instagram_url')} type="url" placeholder="https://instagram.com/..." /></div>
            <div><label className="label">Facebook</label><input {...field('facebook_url')} type="url" placeholder="https://facebook.com/..." /></div>
          </div>
          <div style={{ marginBottom: '1.25rem' }}>
            <label className="label">Opis salonu</label>
            <textarea {...field('description')} className="input" rows={4} placeholder="Opisz swój salon..." />
          </div>
          <label style={{ display: 'flex', alignItems: 'center', gap: '.6rem', cursor: 'pointer', fontSize: '.875rem', fontWeight: 600, marginBottom: '1.5rem' }}>
            <input type="checkbox" checked={form.status === 'active'} onChange={e => setForm(f => ({ ...f, status: e.target.checked ? 'active' : 'draft' }))} style={{ accentColor: '#7c3aed', width: '1rem', height: '1rem' }} />
            Publikuj salon w katalogu
          </label>
          <button type="submit" disabled={saving} className="btn btn-primary" style={{ padding: '.65rem 2rem' }}>
            {saving ? 'Zapisywanie...' : 'Zapisz profil'}
          </button>
        </form>
      )}

      {/* TAB 1 — ZABIEGI */}
      {tab === 1 && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <h2 style={{ fontSize: '1rem', color: '#4c1d95' }}>Zabiegi w ofercie</h2>
            {salon
              ? <button onClick={() => setModal('new')} className="btn btn-primary" style={{ fontSize: '.82rem' }}>+ Dodaj zabieg</button>
              : <span style={{ fontSize: '.82rem', color: '#94a3b8' }}>Najpierw zapisz profil salonu</span>
            }
          </div>
          {services.length === 0
            ? <div className="empty"><h3>Brak zabiegów</h3><p>Dodaj pierwsze zabiegi klikając przycisk powyżej.</p></div>
            : <div className="card" style={{ overflow: 'hidden' }}>
                {services.map((sv, i) => (
                  <div key={sv.id} style={{ display: 'flex', alignItems: 'center', gap: '.75rem', padding: '.8rem 1rem', borderTop: i ? '1px solid #f1f5f9' : 'none' }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontWeight: 600, fontSize: '.875rem', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{sv.service_name}</div>
                      <div style={{ fontSize: '.73rem', color: '#94a3b8', marginTop: '.1rem' }}>
                        {sv.group_id ? GROUP[sv.group_id] + ' · ' : ''}{sv.duration_min ? sv.duration_min + ' min' : ''}
                      </div>
                    </div>
                    <div style={{ fontWeight: 700, color: '#7c3aed', whiteSpace: 'nowrap', fontSize: '.875rem' }}>{priceStr(sv)}</div>
                    <button onClick={() => setModal(sv)} style={{ background: 'none', border: 'none', color: '#7c3aed', fontSize: '.8rem', fontWeight: 700, cursor: 'pointer' }}>Edytuj</button>
                    <button onClick={() => deleteService(sv.id)} style={{ background: 'none', border: 'none', color: '#dc2626', fontSize: '.8rem', fontWeight: 700, cursor: 'pointer' }}>Usuń</button>
                  </div>
                ))}
              </div>
          }
        </div>
      )}

      {/* TAB 2 — ZDJĘCIA */}
      {tab === 2 && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <h2 style={{ fontSize: '1rem', color: '#4c1d95' }}>Zdjęcia salonu</h2>
            {salon
              ? <label className="btn btn-primary" style={{ fontSize: '.82rem', cursor: 'pointer' }}>
                  + Dodaj zdjęcia
                  <input type="file" accept="image/*" multiple style={{ display: 'none' }} onChange={e => uploadPhotos(Array.from(e.target.files))} />
                </label>
              : <span style={{ fontSize: '.82rem', color: '#94a3b8' }}>Najpierw zapisz profil salonu</span>
            }
          </div>
          {uploading && (
            <div style={{ marginBottom: '1rem' }}>
              <div style={{ background: '#e2e8f0', borderRadius: '9999px', height: 6, overflow: 'hidden' }}>
                <div style={{ background: '#7c3aed', height: '100%', width: `${uploadPct}%`, transition: 'width .3s' }} />
              </div>
              <p style={{ fontSize: '.75rem', color: '#64748b', marginTop: '.35rem' }}>Przesyłanie… {uploadPct}%</p>
            </div>
          )}
          {photos.length === 0
            ? <div className="empty"><h3>Brak zdjęć</h3><p>Dodaj zdjęcia swojego salonu.</p></div>
            : <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(180px,1fr))', gap: '.75rem' }}>
                {photos.map(p => (
                  <div key={p.id} style={{ position: 'relative', borderRadius: '.75rem', overflow: 'hidden', border: p.is_cover ? '3px solid #7c3aed' : '1.5px solid #e2e8f0' }}>
                    <img src={p.url} alt="" loading="lazy" style={{ width: '100%', height: 155, objectFit: 'cover', display: 'block' }} />
                    {p.is_cover && <div style={{ position: 'absolute', top: '.4rem', left: '.4rem', background: '#7c3aed', color: '#fff', padding: '.15rem .5rem', borderRadius: '9999px', fontSize: '.65rem', fontWeight: 700 }}>Okładka</div>}
                    <div style={{ position: 'absolute', bottom: '.5rem', left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: '.35rem' }}>
                      {!p.is_cover && <button onClick={() => setCover(p.id)} style={{ background: '#fff', border: 'none', padding: '.25rem .7rem', borderRadius: '9999px', fontSize: '.72rem', fontWeight: 700, cursor: 'pointer', color: '#7c3aed' }}>Okładka</button>}
                      <button onClick={() => deletePhoto(p.id, p.url)} style={{ background: '#dc2626', border: 'none', padding: '.25rem .7rem', borderRadius: '9999px', fontSize: '.72rem', fontWeight: 700, cursor: 'pointer', color: '#fff' }}>Usuń</button>
                    </div>
                  </div>
                ))}
              </div>
          }
        </div>
      )}

      {/* SERVICE MODAL */}
      {modal !== null && (
        <ServiceModal
          service={modal === 'new' ? null : modal}
          salonId={salon?.id}
          onClose={() => setModal(null)}
          onSaved={() => { setModal(null); load(); setTab(1) }}
        />
      )}
    </div>
  )
}

/* ── PAGE ───────────────────────────────────────────────────────── */
export default function PanelPage() {
  const { user, loading } = useAuth()

  return (
    <>
      <Nav />
      {loading
        ? <div className="spinner" />
        : user
          ? <Dashboard user={user} />
          : <AuthForm />
      }
      <footer className="footer">© 2026 BeautyKatalog by Aura Consulting · <a href="../index.html">BeautyPolisa OC</a></footer>
    </>
  )
}
