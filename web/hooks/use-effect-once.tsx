import { DependencyList, EffectCallback, useEffect, useRef } from "react";

export const useEffectOnce = (
  callback: EffectCallback,
  when: DependencyList
) => {
  const hasRunOnce = useRef(false);
  useEffect(() => {
    if (when && !hasRunOnce.current) {
      callback();
      hasRunOnce.current = true;
    }
  }, when);
};
