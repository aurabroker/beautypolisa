import { create } from 'zustand'
import { sb } from '../lib/supabase'

export const useAuth = create((set) => ({
  user: null,
  loading: true,

  init: async () => {
    const { data: { user } } = await sb.auth.getUser()
    set({ user, loading: false })
    sb.auth.onAuthStateChange((_, session) => {
      set({ user: session?.user ?? null })
    })
  },

  signOut: async () => {
    await sb.auth.signOut()
    set({ user: null })
  },
}))
