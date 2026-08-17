"use client";

import { PageHeader } from "@/components/PageHeader";
import { StatCard } from "@/components/StatCard";
import { ErrorBanner } from "@/components/ErrorBanner";
import { Spinner } from "@/components/Spinner";
import { IconBriefcase, IconCheck, IconRupee, IconTrend, IconUsers } from "@/components/icons";
import { adminApi } from "@/lib/api";
import { formatINR, formatNumber, titleCase } from "@/lib/format";
import { useAsync } from "@/lib/useAsync";

export default function DashboardPage() {
  const { data, loading, error, reload } = useAsync(() => adminApi.analytics(), []);

  return (
    <div>
      <PageHeader title="Dashboard" description="Marketplace snapshot — users, jobs, revenue, and commission." />
      {error ? <ErrorBanner message={error} onRetry={reload} /> : null}
      {loading && !data ? <Spinner label="Loading analytics" /> : null}
      {data ? (
        <>
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            <StatCard label="Users" value={formatNumber(data.totalUsers)} hint="Registered accounts" icon={<IconUsers className="h-5 w-5" />} />
            <StatCard label="Active users" value={formatNumber(data.activeUsers)} hint="Currently active" icon={<IconTrend className="h-5 w-5" />} />
            <StatCard label="Jobs posted" value={formatNumber(data.jobsPosted)} hint="All published jobs" icon={<IconBriefcase className="h-5 w-5" />} />
            <StatCard label="Jobs completed" value={formatNumber(data.jobsCompleted)} hint="Finished assignments" icon={<IconCheck className="h-5 w-5" />} />
            <StatCard label="Revenue" value={formatINR(data.revenue)} hint="Gross marketplace volume" icon={<IconRupee className="h-5 w-5" />} />
            <StatCard label="Commission" value={formatINR(data.commission)} hint="Platform earnings" icon={<IconRupee className="h-5 w-5" />} />
          </div>
          {data.extra && Object.keys(data.extra).length > 0 ? (
            <section className="mt-8">
              <h2 className="mb-3 text-sm font-semibold text-ink">Additional metrics</h2>
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                {Object.entries(data.extra).map(([key, value]) => (
                  <div key={key} className="card px-4 py-3">
                    <p className="text-xs text-ink-500">{titleCase(key)}</p>
                    <p className="mt-1 text-lg font-semibold">{formatNumber(value)}</p>
                  </div>
                ))}
              </div>
            </section>
          ) : null}
        </>
      ) : null}
    </div>
  );
}
