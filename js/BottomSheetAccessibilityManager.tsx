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

  const setHiddenExceptBottomSheet = useCallback((element: HTMLElement | null, turn: 'on' | 'off') => {
    if (typeof window === 'undefined') return;

    const allElems = document.body.querySelectorAll<HTMLElement>(
      '*:not(script):not(style):not([inert="true"])'
    );

    allElems.forEach((el) => {
      el.removeAttribute('inert');
    });

    if (turn === 'on' && element) {
      const elementsToHide = Array.from(allElems).filter((el) => {
        return !element.contains(el) && !el.contains(element);
      });

      elementsToHide.forEach((el) => {
        el.setAttribute('inert', 'true');
        el.setAttribute('is-sr-hidden', 'true');
      });
    }

    if (turn === 'off') {
      document.body.querySelectorAll<HTMLElement>('[is-sr-hidden]').forEach((el) => {
        el.removeAttribute('is-sr-hidden');
        el.removeAttribute('inert');
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

    } else if (!isOpen) {
      setHiddenExceptBottomSheet(null, 'off');

      setTimeout(() => {
        if (previousFocusRef.current && previousFocusRef.current !== document.body) {
          previousFocusRef.current.focus();
        }
      }, 100);
    }
  }, [isOpen, bottomSheetId, initialFocusElementId, setHiddenExceptBottomSheet]);

  return <>{children}</>;
};

export default BottomSheetAccessibilityManager; 