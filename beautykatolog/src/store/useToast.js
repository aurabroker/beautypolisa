import { create } from 'zustand'

let nextId = 0

export const useToast = create((set) => ({
  toasts: [],

  toast: (msg, type = 'info', ms = 3500) => {
    const id = ++nextId
    set(s => ({ toasts: [...s.toasts, { id, msg, type }] }))
    setTimeout(() => set(s => ({ toasts: s.toasts.filter(t => t.id !== id) })), ms)
  },
}))
