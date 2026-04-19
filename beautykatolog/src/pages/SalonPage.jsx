import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { sb } from '../lib/supabase'
import Nav from '../components/Nav'
import { MiniMap } from '../components/Map'

const GROUP = { 1: 'Fryzjerstwo', 2: 'Kosmetyka', 3: 'Paznokcie', 4: 'Masaż i SPA', 5: 'Medycyna estetyczna' }

function priceStr(sv) {
  if (!sv.price_from && !sv.price_to) return 'zapytaj'
  if (sv.price_from && sv.price_to && sv.price_to !== sv.price_from) return `${sv.price_from}–${sv.price_to} zł`
  return `od ${sv.price_from ?? sv.price_to} zł`
}

export default function SalonPage() {
  const { id }  = useParams()
  const [salon, setSalon] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [wide, setWide] = useState(window.innerWidth > 768)

  useEffect(() => {
    const mq = window.matchMedia('(min-width:769px)')
    const fn = e => setWide(e.matches)
    mq.addEventListener('change', fn)
    return () => mq.removeEventListener('change', fn)
  }, [])

  useEffect(() => {
    sb.from('salons').select(`
      id,name,slug,tagline,description,city,street,postal_code,
      lat,lng,phone,email_contact,website,status,instagram_url,facebook_url,
      salon_photos(id,url,is_cover,sort_order),
      salon_services(id,service_name,price_from,price_to,duration_min,group_id,is_available)
    `).eq('id', id).maybeSingle()
      .then(({ data, error }) => {
        if (error) { setError(error.message); return }
        if (!data || data.status !== 'active') { setError('Salon nie został znaleziony.'); return }
        document.title = `${data.name} — BeautyKatalog`
        setSalon(data)
        setLoading(false)
      })
  }, [id])

  if (loading) return <><Nav /><div className="spinner" /></>
  if (error)   return <><Nav /><div className="empty" style={{ paddingTop: '5rem' }}><h3>Ups!</h3><p>{error}</p><Link to="/" className="btn btn-primary" style={{ marginTop: '1.25rem' }}>← Wróć do katalogu</Link></div></>

  const s       = salon
  const photos  = (s.salon_photos ?? []).filter(p => p.url).sort((a, b) => (a.sort_order ?? 99) - (b.sort_order ?? 99))
  const cover   = photos.find(p => p.is_cover)?.url ?? photos[0]?.url ?? ''
  const services = (s.salon_services ?? []).filter(sv => sv.is_available !== false)
  const grouped = services.reduce((acc, sv) => {
    const cat = GROUP[sv.group_id] ?? 'Inne zabiegi'
    ;(acc[cat] = acc[cat] ?? []).push(sv)
    return acc
  }, {})

  return (
    <>
      <Nav />

      {/* COVER */}
      <div style={{ height: 300, overflow: 'hidden', background: cover ? 'none' : 'linear-gradient(135deg,#3b0764,#7c3aed)', position: 'relative' }}>
        {cover
          ? <img src={cover} alt={s.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          : <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', fontSize: '5rem' }}>💅</div>
        }
        <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to top,rgba(0,0,0,.65) 0%,transparent 55%)' }} />
        <div style={{ position: 'absolute', bottom: '1.75rem', left: '1.75rem', color: '#fff', maxWidth: 700 }}>
          <h1 style={{ fontSize: 'clamp(1.5rem,4vw,2.4rem)', textShadow: '0 2px 10px rgba(0,0,0,.5)' }}>{s.name}</h1>
          <p style={{ opacity: .9, fontSize: '.9rem', marginTop: '.3rem' }}>
            📍 {s.city}{s.street ? `, ${s.street}` : ''}{s.postal_code ? ` ${s.postal_code}` : ''}
          </p>
        </div>
      </div>

      {/* CONTENT */}
      <div className="container" style={{ paddingTop: '2rem', paddingBottom: '3rem', display: 'grid', gridTemplateColumns: wide ? '1fr 340px' : '1fr', gap: '2rem', alignItems: 'start' }}>

        {/* LEFT */}
        <div>
          {s.description && (
            <section style={{ marginBottom: '2rem' }}>
              <h2 style={{ fontSize: '1.05rem', color: '#4c1d95', marginBottom: '.7rem' }}>O salonie</h2>
              <p style={{ color: '#475569', lineHeight: 1.75, whiteSpace: 'pre-line' }}>{s.description}</p>
            </section>
          )}

          {Object.keys(grouped).length > 0 && (
            <section style={{ marginBottom: '2rem' }}>
              <h2 style={{ fontSize: '1.05rem', color: '#4c1d95', marginBottom: '.9rem' }}>Zabiegi i cennik</h2>
              {Object.entries(grouped).map(([cat, svs]) => (
                <div key={cat} style={{ marginBottom: '1.25rem' }}>
                  <h3 style={{ fontSize: '.78rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '.07em', color: '#7c3aed', marginBottom: '.5rem' }}>{cat}</h3>
                  <div className="card" style={{ overflow: 'hidden' }}>
                    {svs.map((sv, i) => (
                      <div key={sv.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem', padding: '.75rem 1rem', borderTop: i ? '1px solid #f1f5f9' : 'none' }}>
                        <div>
                          <div style={{ fontSize: '.9rem', fontWeight: 500 }}>{sv.service_name}</div>
                          {sv.duration_min && <div style={{ fontSize: '.73rem', color: '#94a3b8', marginTop: '.1rem' }}>⏱ {sv.duration_min} min</div>}
                        </div>
                        <div style={{ fontWeight: 700, color: '#7c3aed', whiteSpace: 'nowrap', fontSize: '.88rem', flexShrink: 0 }}>{priceStr(sv)}</div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </section>
          )}

          {photos.length > 1 && (
            <section style={{ marginBottom: '2rem' }}>
              <h2 style={{ fontSize: '1.05rem', color: '#4c1d95', marginBottom: '.9rem' }}>Zdjęcia</h2>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(160px,1fr))', gap: '.6rem' }}>
                {photos.map(p => (
                  <img key={p.id} src={p.url} alt={s.name} loading="lazy"
                    style={{ width: '100%', height: 150, objectFit: 'cover', borderRadius: '.6rem', cursor: 'zoom-in' }}
                    onClick={() => window.open(p.url, '_blank')}
                  />
                ))}
              </div>
            </section>
          )}
        </div>

        {/* SIDEBAR */}
        <aside style={{ position: wide ? 'sticky' : 'static', top: 80, display: 'flex', flexDirection: 'column', gap: '1rem' }}>

          <div className="card" style={{ padding: '1.25rem' }}>
            <h3 style={{ fontSize: '.85rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.06em', color: '#4c1d95', marginBottom: '.85rem' }}>Kontakt</h3>
            {s.phone     && <a href={`tel:${s.phone}`}     style={{ display: 'flex', gap: '.5rem', fontSize: '.875rem', marginBottom: '.5rem' }}>📞 {s.phone}</a>}
            {s.email_contact && <a href={`mailto:${s.email_contact}`} style={{ display: 'flex', gap: '.5rem', fontSize: '.875rem', marginBottom: '.5rem' }}>✉️ {s.email_contact}</a>}
            {s.website   && <a href={s.website} target="_blank" rel="noopener" style={{ display: 'flex', gap: '.5rem', fontSize: '.875rem', marginBottom: '.5rem', color: '#7c3aed' }}>🌐 Strona internetowa ↗</a>}
            {s.instagram_url && <a href={s.instagram_url} target="_blank" rel="noopener" style={{ display: 'flex', gap: '.5rem', fontSize: '.875rem', marginBottom: '.5rem', color: '#7c3aed' }}>📸 Instagram ↗</a>}
            {!s.phone && !s.email_contact && !s.website && <p style={{ fontSize: '.82rem', color: '#94a3b8' }}>Brak danych kontaktowych</p>}
          </div>

          {s.lat && s.lng && (
            <div className="card" style={{ overflow: 'hidden', padding: 0 }}>
              <div style={{ height: 210 }}>
                <MiniMap lat={s.lat} lng={s.lng} name={s.name} />
              </div>
            </div>
          )}

          <div className="card" style={{ padding: '1.25rem', textAlign: 'center', background: '#faf5ff', borderColor: '#ddd6fe' }}>
            <p style={{ fontSize: '.8rem', color: '#64748b', marginBottom: '.75rem' }}>Jesteś właścicielem tego salonu?</p>
            <Link to="/panel" className="btn btn-outline" style={{ width: '100%', justifyContent: 'center' }}>Zarządzaj profilem</Link>
          </div>

          <Link to="/" style={{ fontSize: '.8rem', color: '#7c3aed', fontWeight: 700, textAlign: 'center' }}>← Wróć do katalogu</Link>
        </aside>
      </div>

      <footer className="footer">
        © 2026 BeautyKatalog by Aura Consulting · <a href="../index.html">BeautyPolisa OC</a>
      </footer>
    </>
  )
}
