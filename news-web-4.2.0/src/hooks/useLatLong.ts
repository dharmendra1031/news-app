import { useSelector } from 'react-redux';
import { locationSelector } from '@/redux/reducers/settingsSlice';

export const useLatLong = (): { latitude: number | undefined; longitude: number | undefined } => {
    const { lat, long } = useSelector(locationSelector);
    return { latitude: lat ?? undefined, longitude: long ?? undefined };
};
