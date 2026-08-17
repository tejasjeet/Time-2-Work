"use client";

import { FormEvent, useEffect, useState } from "react";
import { ErrorBanner } from "@/components/ErrorBanner";
import { PageHeader } from "@/components/PageHeader";
import { Spinner } from "@/components/Spinner";
import { useToast } from "@/components/Toast";
import { adminApi } from "@/lib/api";
import { useAsync } from "@/lib/useAsync";

export default function SettingsPage() {
  const toast = useToast();
  const { data, loading, error, reload } = useAsync(() => adminApi.settings(), []);
  const [form, setForm] = useState({
    jobPostingFee: 19,
    commissionPercent: 10,
    primaryRadiusKm: 5,
    secondaryRadiusKm: 10,
    referralReward: 0,
  });
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!data) return;
    setForm({
      jobPostingFee: data.jobPostingFee,
      commissionPercent: data.commissionPercent,
      primaryRadiusKm: data.primaryRadiusKm,
      secondaryRadiusKm: data.secondaryRadiusKm,
      referralReward: data.referralReward,
    });
  }, [data]);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    try {
      await adminApi.updateSettings({
        jobPostingFee: Number(form.jobPostingFee),
        commissionPercent: Number(form.commissionPercent),
        primaryRadiusKm: Number(form.primaryRadiusKm),
        secondaryRadiusKm: Number(form.secondaryRadiusKm),
        referralReward: Number(form.referralReward),
      });
      toast("Settings saved");
      await reload();
    } catch (err) {
      toast(err instanceof Error ? err.message : "Save failed", "err");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <PageHeader title="Settings" description="Marketplace fee, commission, and matching radii. Changes apply to new jobs." />
      {error ? <ErrorBanner message={error} onRetry={reload} /> : null}
      {loading && !data ? <Spinner label="Loading settings" /> : null}

      <form onSubmit={onSubmit} className="card max-w-2xl p-6">
        <div className="grid gap-5 sm:grid-cols-2">
          <div>
            <label className="label" htmlFor="jobPostingFee">
              Job posting fee (₹)
            </label>
            <input
              id="jobPostingFee"
              className="input"
              type="number"
              min={0}
              step="1"
              value={form.jobPostingFee}
              onChange={(e) => setForm((f) => ({ ...f, jobPostingFee: Number(e.target.value) }))}
            />
            <p className="mt-1 text-xs text-ink-400">Charged before a job is published. Default 19.</p>
          </div>
          <div>
            <label className="label" htmlFor="commissionPercent">
              Commission (%)
            </label>
            <input
              id="commissionPercent"
              className="input"
              type="number"
              min={0}
              max={100}
              step="0.5"
              value={form.commissionPercent}
              onChange={(e) => setForm((f) => ({ ...f, commissionPercent: Number(e.target.value) }))}
            />
            <p className="mt-1 text-xs text-ink-400">Taken from each completed worker payout. Default 10.</p>
          </div>
          <div>
            <label className="label" htmlFor="primaryRadiusKm">
              Primary radius (KM)
            </label>
            <input
              id="primaryRadiusKm"
              className="input"
              type="number"
              min={1}
              step="1"
              value={form.primaryRadiusKm}
              onChange={(e) => setForm((f) => ({ ...f, primaryRadiusKm: Number(e.target.value) }))}
            />
            <p className="mt-1 text-xs text-ink-400">Default nearby feed radius. Plan default 5 KM.</p>
          </div>
          <div>
            <label className="label" htmlFor="secondaryRadiusKm">
              Secondary radius (KM)
            </label>
            <input
              id="secondaryRadiusKm"
              className="input"
              type="number"
              min={1}
              step="1"
              value={form.secondaryRadiusKm}
              onChange={(e) => setForm((f) => ({ ...f, secondaryRadiusKm: Number(e.target.value) }))}
            />
            <p className="mt-1 text-xs text-ink-400">Extended filter radius. Plan default 10 KM.</p>
          </div>
          <div className="sm:col-span-2">
            <label className="label" htmlFor="referralReward">
              Referral reward (₹)
            </label>
            <input
              id="referralReward"
              className="input"
              type="number"
              min={0}
              step="1"
              value={form.referralReward}
              onChange={(e) => setForm((f) => ({ ...f, referralReward: Number(e.target.value) }))}
            />
            <p className="mt-1 text-xs text-ink-400">Phase 2 field. Stored now so payouts can go live later.</p>
          </div>
        </div>
        <div className="mt-6 flex justify-end">
          <button type="submit" className="btn-primary" disabled={busy || loading}>
            {busy ? "Saving…" : "Save settings"}
          </button>
        </div>
      </form>
    </div>
  );
}
