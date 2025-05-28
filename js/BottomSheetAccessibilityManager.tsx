import { useCallback, useEffect, useRef } from 'react';

interface BottomSheetAccessibilityManagerProps {
  isOpen: boolean;
  bottomSheetId: string;
  children: React.ReactNode;
  initialFocusElementId?: string;
}

const BottomSheetAccessibilityManager = ({
  isOpen,
  bottomSheetId,
  children,
  initialFocusElementId
}: BottomSheetAccessibilityManagerProps) => {
  const previousFocusRef = useRef<HTMLElement | null>(null);

  const setHiddenExceptBottomSheet = useCallback((bottomSheetNode: HTMLElement | null, turn: 'on' | 'off') => {
    if (typeof window === 'undefined') return;

    if (turn === 'on' && bottomSheetNode) {
      const elementsToProcess = document.body.querySelectorAll<HTMLElement>(
        '*:not(script):not(style)'
      );
      elementsToProcess.forEach((el) => {
        if (el !== bottomSheetNode && !bottomSheetNode.contains(el) && !el.contains(bottomSheetNode)) {
          if (!el.hasAttribute('inert')) {
            el.setAttribute('inert', 'true');
            el.setAttribute('data-bm-inerted', 'true');
          }
        }
      });
    } else if (turn === 'off') {
      document.body.querySelectorAll<HTMLElement>('[data-bm-inerted="true"]').forEach((el) => {
        el.removeAttribute('inert');
        el.removeAttribute('data-bm-inerted');
      });
    }
  }, []);

  useEffect(() => {
    const bottomSheet = document.getElementById(bottomSheetId);

    if (isOpen && bottomSheet) {
      previousFocusRef.current = document.activeElement as HTMLElement;
      setHiddenExceptBottomSheet(bottomSheet, 'on');

      setTimeout(() => {
        if (initialFocusElementId) {
          const initialFocusElement = document.getElementById(initialFocusElementId);
          if (initialFocusElement) {
            initialFocusElement.focus();
            return;
          }
        }
        const focusableElements = bottomSheet.querySelectorAll<HTMLElement>(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        if (focusableElements.length > 0) {
          focusableElements[0].focus();
        } else {
          bottomSheet.setAttribute('tabindex', '-1');
          bottomSheet.focus();
        }
      }, 100);

      return () => {
        setHiddenExceptBottomSheet(null, 'off');
        setTimeout(() => {
          if (previousFocusRef.current && document.contains(previousFocusRef.current)) {
            previousFocusRef.current.focus();
          }
        }, 50);
      };
    }
  }, [isOpen, bottomSheetId, initialFocusElementId, setHiddenExceptBottomSheet]);

  return <>{children}</>;
};

export default BottomSheetAccessibilityManager;
