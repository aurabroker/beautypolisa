import { useState, useEffect, useMemo } from 'react'
import { sb } from '../lib/supabase'
import Nav from '../components/Nav'
import SalonCard from '../components/SalonCard'
import { CatalogMap } from '../components/Map'

const PER_PAGE = 12

export default function HomePage() {
  const [salons, setSalons]     = useState([])
  const [loading, setLoading]   = useState(true)
  const [error, setError]       = useState(null)
  const [search, setSearch]     = useState('')
  const [city, setCity]         = useState('')
  const [showMap, setShowMap]   = useState(false)
  const [page, setPage]         = useState(1)

  useEffect(() => {
    sb.from('salons')
      .select('id,name,slug,city,street,tagline,description,lat,lng,salon_photos(url,is_cover),salon_services(id)')
      .eq('status', 'active')
      .order('created_at', { ascending: false })
      .then(({ data, error }) => {
        if (error) setError(error.message)
        else setSalons(data ?? [])
        setLoading(false)
      })
  }, [])

  const cities = useMemo(() =>
    [...new Set(salons.map(s => s.city).filter(Boolean))].sort((a, b) => a.localeCompare(b, 'pl'))
  , [salons])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return salons.filter(s => {
      if (city && s.city !== city) return false
      if (q && !`${s.name} ${s.city} ${s.description ?? ''}`.toLowerCase().includes(q)) return false
      return true
    })
  }, [salons, search, city])

  const visible  = filtered.slice(0, page * PER_PAGE)
  const hasMore  = filtered.length > visible.length

  const countLabel = filtered.length === 1 ? '1 salon'
    : filtered.length < 5 ? `${filtered.length} salony`
    : `${filtered.length} salonów`

  function handleSearch(e) {
    e.preventDefault()
    setPage(1)
  }

  return (
    <>
      <Nav />

      {/* HERO */}
      <section style={{ background: 'linear-gradient(135deg,#3b0764 0%,#7c3aed 55%,#a855f7 100%)', padding: '4rem 0 3rem', color: '#fff' }}>
        <div className="container">
          <p style={{ fontSize: '.8rem', fontWeight: 700, letterSpacing: '.12em', textTransform: 'uppercase', opacity: .7, marginBottom: '.5rem' }}>BeautyKatalog · Polska</p>
          <h1 style={{ fontSize: 'clamp(1.8rem,5vw,3rem)', marginBottom: '.6rem' }}>Znajdź salon beauty<br />w swoim mieście</h1>
          <p style={{ fontSize: '1rem', opacity: .8, marginBottom: '2rem', maxWidth: 520 }}>
            Przeglądaj salony kosmetyczne, fryzjerskie, podologiczne i kosmetologiczne w całej Polsce.
          </p>
          <form onSubmit={handleSearch} style={{ display: 'flex', gap: '.6rem', maxWidth: 580 }}>
            <input
              value={search}
              onChange={e => { setSearch(e.target.value); setPage(1) }}
              placeholder="Szukaj salonu, miasta, zabiegu..."
              style={{ flex: 1, padding: '.8rem 1.1rem', border: 'none', borderRadius: '.7rem', fontSize: '.95rem', outline: 'none', fontFamily: 'inherit' }}
            />
            <button type="submit" className="btn" style={{ padding: '.8rem 1.5rem', fontSize: '.95rem', flexShrink: 0, borderRadius: '.7rem', background: '#fff', color: '#7c3aed', fontWeight: 700 }}>
              Szukaj
            </button>
          </form>
        </div>
      </section>

      {/* FILTERS BAR */}
      <div style={{ background: '#fff', borderBottom: '1px solid #e2e8f0', position: 'sticky', top: 58, zIndex: 90 }}>
        <div className="container" style={{ padding: '.65rem 1.25rem', display: 'flex', alignItems: 'center', gap: '.75rem', flexWrap: 'wrap' }}>
          <select value={city} onChange={e => { setCity(e.target.value); setPage(1) }} className="input" style={{ width: 'auto', minWidth: 170 }}>
            <option value="">Wszystkie miasta</option>
            {cities.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
          <span style={{ fontSize: '.8rem', color: '#64748b', fontWeight: 600, marginLeft: 'auto' }}>{!loading && countLabel}</span>
          <button onClick={() => setShowMap(v => !v)} className="btn btn-outline" style={{ padding: '.4rem .9rem', fontSize: '.8rem' }}>
            {showMap ? '☰ Lista' : '🗺 Mapa'}
          </button>
        </div>
      </div>

      {/* MAIN */}
      <main className="container" style={{ paddingTop: '1.75rem', paddingBottom: '3rem' }}>

        {/* MAP */}
        {showMap && (
          <div style={{ height: 420, borderRadius: '1rem', overflow: 'hidden', marginBottom: '1.75rem', border: '1px solid #e2e8f0' }}>
            <CatalogMap salons={filtered} />
          </div>
        )}

        {/* GRID */}
        {loading ? (
          <div className="spinner" />
        ) : error ? (
          <div className="empty"><h3>Błąd</h3><p>{error}</p></div>
        ) : filtered.length === 0 ? (
          <div className="empty"><h3>Brak wyników</h3><p>Spróbuj innych słów kluczowych lub usuń filtry.</p></div>
        ) : (
          <>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(300px,1fr))', gap: '1.25rem' }}>
              {visible.map(s => <SalonCard key={s.id} salon={s} />)}
            </div>
            {hasMore && (
              <div style={{ textAlign: 'center', marginTop: '2rem' }}>
                <button onClick={() => setPage(p => p + 1)} className="btn btn-outline" style={{ padding: '.65rem 2rem' }}>
                  Załaduj więcej
                </button>
              </div>
            )}
          </>
        )}
      </main>

      <footer className="footer">
        © 2026 BeautyKatalog by Aura Consulting · <a href="../index.html">BeautyPolisa OC</a>
      </footer>
    </>
  )
}
