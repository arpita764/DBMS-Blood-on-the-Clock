"use client";

import {
  ButtonHTMLAttributes,
  InputHTMLAttributes,
  ReactNode,
  SelectHTMLAttributes,
} from "react";

export function cn(...parts: (string | false | undefined | null)[]): string {
  return parts.filter(Boolean).join(" ");
}

export function Badge({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
        className
      )}
    >
      {children}
    </span>
  );
}

export function Card({
  title,
  actions,
  children,
  className,
}: {
  title?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={cn("rounded-xl border border-gray-200 bg-white shadow-sm", className)}>
      {(title || actions) && (
        <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3">
          <div className="font-semibold text-gray-800">{title}</div>
          <div className="flex gap-2">{actions}</div>
        </div>
      )}
      <div className="p-4">{children}</div>
    </div>
  );
}

export function StatCard({
  label,
  value,
  sub,
  tone = "gray",
}: {
  label: string;
  value: ReactNode;
  sub?: ReactNode;
  tone?: "red" | "amber" | "blue" | "green" | "gray";
}) {
  const tones = {
    red: "text-red-700",
    amber: "text-amber-600",
    blue: "text-blue-700",
    green: "text-green-700",
    gray: "text-gray-800",
  };
  return (
    <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
      <div className="text-xs font-medium uppercase tracking-wide text-gray-500">
        {label}
      </div>
      <div className={cn("mt-2 text-3xl font-bold", tones[tone])}>{value}</div>
      {sub && <div className="mt-1 text-xs text-gray-500">{sub}</div>}
    </div>
  );
}

type BtnProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "danger" | "ghost";
};

export function Button({ variant = "primary", className, ...props }: BtnProps) {
  const variants = {
    primary: "bg-brand-600 text-white hover:bg-brand-700 disabled:bg-gray-300",
    secondary:
      "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 disabled:opacity-50",
    danger: "bg-white text-red-600 border border-red-200 hover:bg-red-50 disabled:opacity-50",
    ghost: "text-gray-600 hover:bg-gray-100",
  };
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center rounded-lg px-3 py-1.5 text-sm font-medium transition disabled:cursor-not-allowed",
        variants[variant],
        className
      )}
      {...props}
    />
  );
}

export function Input({
  label,
  className,
  ...props
}: InputHTMLAttributes<HTMLInputElement> & { label?: string }) {
  return (
    <label className="block">
      {label && (
        <span className="mb-1 block text-sm font-medium text-gray-700">{label}</span>
      )}
      <input
        className={cn(
          "w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500",
          className
        )}
        {...props}
      />
    </label>
  );
}

export function Select({
  label,
  className,
  children,
  ...props
}: SelectHTMLAttributes<HTMLSelectElement> & { label?: string }) {
  return (
    <label className="block">
      {label && (
        <span className="mb-1 block text-sm font-medium text-gray-700">{label}</span>
      )}
      <select
        className={cn(
          "w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500",
          className
        )}
        {...props}
      >
        {children}
      </select>
    </label>
  );
}

export function Spinner() {
  return (
    <div className="flex items-center gap-2 text-gray-500">
      <div className="h-4 w-4 animate-spin rounded-full border-2 border-gray-300 border-t-brand-600" />
      <span>Loading…</span>
    </div>
  );
}

export function EmptyState({ message }: { message: string }) {
  return <div className="py-10 text-center text-sm text-gray-400">{message}</div>;
}

export function Modal({
  open,
  onClose,
  title,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title?: ReactNode;
  children: ReactNode;
}) {
  if (!open) return null;
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
    >
      <div
        className="w-full max-w-lg rounded-xl bg-white shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between border-b px-4 py-3">
          <div className="font-semibold text-gray-800">{title}</div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
            aria-label="Close"
          >
            ✕
          </button>
        </div>
        <div className="p-4">{children}</div>
      </div>
    </div>
  );
}

export function Th({ children, className }: { children?: ReactNode; className?: string }) {
  return (
    <th
      className={cn(
        "border-b border-gray-200 px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-gray-500",
        className
      )}
    >
      {children}
    </th>
  );
}

export function Td({ children, className }: { children?: ReactNode; className?: string }) {
  return <td className={cn("px-3 py-2 text-sm text-gray-700", className)}>{children}</td>;
}
