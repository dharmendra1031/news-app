<?php

namespace App\Services;

class BootstrapTableService {
    private static string $defaultClasses = "btn icon btn-xs btn-rounded btn-icon rounded-pill";

    /**
     * @param string $iconClass
     * @param string $url
     * @param array $customClass
     * @param array $customAttributes
     * @param string $iconText
     * @return string
     */
    public static function button(string $iconClass, string $url, array $customClass = [], array $customAttributes = [], string $iconText = '') {
        $customClassStr = implode(" ", $customClass);
        $class = self::$defaultClasses . ' ' . $customClassStr;
        $attributes = '';
        if (count($customAttributes) > 0) {
            foreach ($customAttributes as $key => $value) {
                $attributes .= $key . '="' . $value . '" ';
            }
        }
        return '<a href="' . $url . '" class="' . $class . '" ' . $attributes . '><i class="' . $iconClass . '"></i>' . $iconText . '</a>&nbsp;&nbsp;';
    }


    public static function dropdown(
        string $iconClass,
        array $dropdownItems,
        array $customClass = [],
        array $customAttributes = []
    ) {
        // Generate unique ID for each dropdown to avoid conflicts
        $uniqueId = 'dropdownMenuButton_' . uniqid();
        $customClassStr = implode(" ", $customClass);
        $class = 'dropdown ' . $customClassStr;
        $attributes = '';

        if (count($customAttributes) > 0) {
            foreach ($customAttributes as $key => $value) {
                $attributes .= $key . '="' . $value . '" ';
            }
        }

        // Build dropdown structure matching the working pattern from CategoryController
        $dropdown = '<div class="' . trim($class) . '" ' . $attributes . '>';
        $dropdown .= '<a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">';
        $dropdown .= '<button class="btn btn-primary btn-sm px-3 operatebtn"><i class="' . $iconClass . '"></i></button>';
        $dropdown .= '</a>';
        $dropdown .= '<div class="dropdown-menu dropdown-scrollbar" aria-labelledby="' . $uniqueId . '">';

        foreach ($dropdownItems as $item) {
            // Extract standard properties
            $url = isset($item['url']) ? $item['url'] : 'javascript:void(0)';
            $icon = isset($item['icon']) ? '<i class="' . $item['icon'] . '"></i> ' : '';
            $text = isset($item['text']) ? $item['text'] : '';
            $itemClass = isset($item['class']) ? ' ' . $item['class'] : '';

            // Build attributes - include all keys except url, text, icon, class
            $itemAttributes = '';
            $excludedKeys = ['url', 'text', 'icon', 'class'];

            foreach ($item as $key => $value) {
                if (!in_array($key, $excludedKeys)) {
                    // Support nested attributes array or direct attributes
                    if ($key === 'attributes' && is_array($value)) {
                        foreach ($value as $attrKey => $attrValue) {
                            $itemAttributes .= $attrKey . '="' . htmlspecialchars($attrValue, ENT_QUOTES) . '" ';
                        }
                    } else {
                        $itemAttributes .= $key . '="' . htmlspecialchars($value, ENT_QUOTES) . '" ';
                    }
                }
            }

            $dropdown .= '<a class="dropdown-item' . $itemClass . '" href="' . $url . '" ' . trim($itemAttributes) . '>' . $icon . $text . '</a>';
        }

        $dropdown .= '</div>';
        $dropdown .= '</div>';

        return $dropdown;
    }



    /**
     * @param $url
     * @param bool $modal
     * @param string $dataTarget
     * @param null $customClass
     * @param null $id
     * @param string $iconClass
     * @param null $onClick
     * @param null $dataId
     * @return string
     */
    public static function editButton($url, bool $modal = false, $dataTarget = "#editDataModal", $customClass = null, $id = null, $iconClass = "fa fa-edit", $onClick = null, $dataId = null) {
        if ($modal) {
            // Build modal button HTML directly to match the manual button structure
            $classes = ["btn", "btn-icon", "btn-primary", "text-white", "edit-data"];
            if ($customClass) {
                $classes[] = $customClass;
            }

            $attributes = [
                "data-id"       => $dataId,
                "data-toggle"   => "modal",
                "data-target"   => $dataTarget,
                "title"         => trans("edit"),
            ];

            if ($id) {
                $attributes["id"] = $id;
            }

            if ($onClick) {
                $attributes["onclick"] = $onClick;
            }

            $attributesStr = '';
            foreach ($attributes as $key => $value) {
                if ($value !== null) {
                    $attributesStr .= $key . '="' . htmlspecialchars($value, ENT_QUOTES) . '" ';
                }
            }

            return '<a href="javascript:void(0)" class="' . implode(" ", $classes) . '" ' . trim($attributesStr) . '><em class="' . $iconClass . '"></em></a>';
        } else {
            // For non-modal buttons, use the standard button method
            $baseClasses = ["btn-primary"];
            if ($customClass) {
                $baseClasses[] = $customClass;
            }
            $customAttributes = [
                "title" => trans("edit")
            ];
            return self::button($iconClass, $url, $baseClasses, $customAttributes);
        }
    }

    /**
     * @param $url
     * @param null $id
     * @param null $dataId
     * @param null $dataCategory
     * @param null $customClass
     * @return string
     */
    public static function deleteButton($url, $id = null, $dataId = null, $dataCategory = null, $customClass = null) {
        $customClass = ["delete-form", "btn-danger" . $customClass];
        $customAttributes = [
            "title"         => trans("delete"),
            "id"            => $id,
            "data-id"       => $dataId,
            "data-category" => $dataCategory
        ];
        // icon size 16px
        $iconClass = "fas fa-trash";
        return self::button($iconClass, $url, $customClass, $customAttributes);
    }

    /**
     * Renders a plain delete button (no dropdown wrapper).
     * Use this when the operate column contains only a delete action.
     *
     * @param string      $url      data-url for the delete-form handler
     * @param int|string  $dataId   row ID passed as data-id
     * @param string|null $customClass  additional CSS classes
     * @return string
     */
    public static function singleDeleteButton(string $url, $dataId, ?string $customClass = null): string {
        $classes = 'btn btn-primary text-white delete-form';
        if ($customClass) {
            $classes .= ' ' . $customClass;
        }
        return '<a data-url="' . $url . '" class="' . $classes . '" data-id="' . $dataId . '" title="' . trans('delete') . '">'
            . '<span class="fa fa-trash"></span>'
            . '</a>';
    }

    /**
     * @param $url
     * @param string $title
     * @return string
     */
    public static function restoreButton($url, string $title = "Restore") {
        $customClass = ["btn-gradient-success", "restore-data"];
        $customAttributes = [
            "title" => trans($title),
        ];
        $iconClass = "fa fa-refresh";
        return self::button($iconClass, $url, $customClass, $customAttributes);
    }

    /**
     * @param $url
     * @return string
     */
    public static function trashButton($url) {
        $customClass = ["btn-gradient-danger", "trash-data"];
        $customAttributes = [
            "title" => trans("Delete Permanent"),
        ];
        $iconClass = "fa fa-times";
        return self::button($iconClass, $url, $customClass, $customAttributes);
    }

    public static function optionButton($url) {
        $customClass = ["btn-option"];
        $customAttributes = [
            "title" => trans("View Option Data"),
        ];
        $iconClass = "bi bi-gear";
        $iconText = " Options";
        return self::button($iconClass, $url, $customClass, $customAttributes, $iconText);
    }
}
